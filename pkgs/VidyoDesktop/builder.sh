source $stdenv/setup
PATH=$dpkg/bin:$PATH

dpkg -x $src unpacked

mkdir -p $out/bin
cp -r unpacked/* $out/

sed -i -e "s|/opt/vidyo|$out/opt/vidyo|" $out/usr/bin/VidyoDesktop


ln -s $out/usr/bin/VidyoDesktop $out/bin/VidyoDesktop
touch $out/etc/issue

#wrapProgram $out/bin/VidyoDesktop \
#    --set PULSE_LATENCY_MSEC "60" \
#    --set VIDYO_AUDIO_FRAMEWORK "ALSA"
