#!/usr/bin/env ruby
require "open-uri"

Source = Struct.new(:hash, :arch, :locale, :filename)

base_uri = URI.parse("http://download-installer.cdn.mozilla.net/pub/firefox/nightly/")
arches = ["linux-i686", "linux-x86_64"]
locales = ["en-US"]

# Find latest release
year_uri = base_uri.merge(
  open(base_uri).read.scan(/#{base_uri.path}\d{4}\//).last
)
month_uri = year_uri.merge(
  open(year_uri).read.scan(/#{year_uri.path}\d{2}\//).last
)
day_uri = month_uri.merge(
  open(month_uri).read.scan(/#{month_uri.path}[^\/]+mozilla-central\//).last
)
base_url = day_uri

version = open(base_url).read.match("/firefox-([^-]+).#{locales.first}")[1]

sources = []

locales.each do |locale|
  arches.each do |arch|
    basename = "firefox-#{version}.#{locale}.#{arch}"
    filename = basename + ".tar.bz2"
    url = base_url.merge("#{basename}.checksums")
    sha512 = open(url).each_line
      .find(filename).first
      .split(" ").first
    sources << Source.new(sha512, arch, locale, filename)
  end
end

sources = sources.sort_by do |source|
  [source.locale, source.arch]
end

puts(<<"EOH")
# This file is generated from generate_sources_dev.rb. DO NOT EDIT.
# Execute the following command to update the file.
#
# ruby generate_sources_dev.rb > dev_sources.nix

{
  version = "#{version}";
  sources = [
EOH

sources.each do |source|
  puts(%Q|    { url = "#{base_url.merge(source.filename)}"; locale = "#{source.locale}"; arch = "#{source.arch}"; sha512 = "#{source.hash}"; }|)
end

puts(<<'EOF')
  ];
}
EOF
