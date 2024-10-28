google-chrome --user-data-dir=/ara/portable/chrome/robert --enable-logging --vmmodule=*/webrtc/*=2
tail -f /ara/portable/chrome/robert/chrome_debug.log

cd /ara/devel/sandbox/chromium/src
gn gen out/Default --args="enable_nacl=false is_component_build=true symbol_level=0 blink_symbol_level=0 v8_symbol_level=0 proprietary_codecs=true ffmpeg_branding=\"Chrome\" is_debug=false"
autoninja -C out/Default chrome

Using no-sandbox to avoid sigsegv crash:
./out/Default/chrome --enable-logging --vmodule=*/webrtc/*=1 --no-sandbox

List options:
gn args out/Default --list


docker exec -it scummvm-2.7.1-mk4bpU1oi8 bash
su gamer
(show latency)
pactl list sinks

rm -rf /ara/incoming/dots
docker cp scummvm-2.7.1-0:/tmp/dots /ara/incoming
cd /ara/incoming/dots
find . -type f -name "*.dot" -exec dot -Tpng {} -o {}.png \;


Fix 1:

UPD: noticed growing of "UDP send buffer errors" on the server side,
so updating:

sudo sysctl net.core.wmem_default=2097152
sudo sysctl net.core.wmem_max=2097152

"UDP send buffer errors" are visible from the `netstat -su` output.

Fix 2:

audio/video ts diff

Cheats: 

- disable server-side cursor (ximagesrc show-pointer=false) (works only on main desktop or in games using main desktop cursor)
- cursor trick: enable client side cursor and disable server side one. This is tricky to do in all apps cos it requires resources modification.

Whenever new jukebox image is published in ECR, all cluster nodes should perform docker pull to make all runs instant
(use jukeboxs' /cluster/pull_image endpoint).

gstreamer fix (-100ms of latency in a google chrome, disable sync of the audio/video streams):

  //t_rtp = src->last_rtptime;
  t_rtp = 1307;
