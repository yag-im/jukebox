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


# Rollback old docker images

  docker pull ghcr.io/yag-im/jukebox/x11_gpu-intel_wine@sha256:750ae73211a06308936369893b6122e4250113b7d52868e38007add3da97dba0
  docker tag ghcr.io/yag-im/jukebox/x11_gpu-intel_wine@sha256:750ae73211a06308936369893b6122e4250113b7d52868e38007add3da97dba0 ghcr.io/yag-im/jukebox/x11_gpu-intel_wine:10.0

  docker pull ghcr.io/yag-im/jukebox/x11_gpu-intel_scummvm@sha256:846f095906e44a652f539b47a088071ffa5974faa38c9722c464e72438f2e808
  docker tag ghcr.io/yag-im/jukebox/x11_gpu-intel_scummvm@sha256:846f095906e44a652f539b47a088071ffa5974faa38c9722c464e72438f2e808 ghcr.io/yag-im/jukebox/x11_gpu-intel_scummvm:2.9.1

  docker pull ghcr.io/yag-im/jukebox/x11_gpu-intel_dosbox-x@sha256:6dd2a7224a9a2f55c921742b38d40834e34ae68708babadcb075f8c86d46ba53
  docker tag ghcr.io/yag-im/jukebox/x11_gpu-intel_dosbox-x@sha256:6dd2a7224a9a2f55c921742b38d40834e34ae68708babadcb075f8c86d46ba53 ghcr.io/yag-im/jukebox/x11_gpu-intel_dosbox-x:2024.12.04

  docker pull ghcr.io/yag-im/jukebox/x11_gpu-intel_dosbox-staging@sha256:0433283376a060fe67ba104c60b2b480e673fa889fa9f434130c7c269d18c9f4
  docker tag ghcr.io/yag-im/jukebox/x11_gpu-intel_dosbox-staging@sha256:0433283376a060fe67ba104c60b2b480e673fa889fa9f434130c7c269d18c9f4 ghcr.io/yag-im/jukebox/x11_gpu-intel_dosbox-staging:0.82.0

  docker pull ghcr.io/yag-im/jukebox/x11_gpu-intel_dosbox@sha256:4ca610598e79f146a48f197ecb9ae676c6f0b1c07c403ffdf1ca704fe200c3e3
  docker tag ghcr.io/yag-im/jukebox/x11_gpu-intel_dosbox@sha256:4ca610598e79f146a48f197ecb9ae676c6f0b1c07c403ffdf1ca704fe200c3e3 ghcr.io/yag-im/jukebox/x11_gpu-intel_dosbox:0.74-3

  ...

  dangling=$(docker images -f "dangling=true" -q) && [ -n "$dangling" ] && docker rmi $dangling || echo "No dangling images to remove."
