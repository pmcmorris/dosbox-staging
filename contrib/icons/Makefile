.PHONY: help clean

help:
	@echo "Re-generate icons in platform specific formats."
	@echo
	@echo "Available targets:"
	@echo "  dosbox-staging.ico  - Windows format"
	@echo "  dosbox-staging.icns - macOS format"
	@echo "  clean               - clean intermediate files"

##
#  Create an icon using Windows .ico format.
#
#  Windows users are expected to create icons using GUI applications, and
#  there's no good Windows-native command line program for this usecase.
#
#  This target is using convert (package imagemagick) to resize icons
#  and icotool (package icoutils) to create an .ico file.
#
dosbox-staging.ico: \
		icon_256x256.png \
		icon_48x48.png \
		icon_32x32.png \
		dosbox-staging-16.png
	icotool -c $^ -o $@

icon_%.png: dosbox-staging-1024.png
	convert -resize $(shell echo $@ | sed 's|icon_\(.*\).png|\1|') $< $@

##
#  Create an icon using macOS .icns format.
#
#  Uses sips, which is available by default on macOS.
#
dosbox-staging.icns: dosbox-staging.iconset
	iconutil -c icns dosbox-staging.iconset

dosbox-staging.iconset: dosbox-staging-1024.png dosbox-staging-16.png
	mkdir -p "$@"
	cp dosbox-staging-16.png $@/icon_16x16.png
	sips -z 32 32   $< --out $@/icon_16x16@2x.png
	sips -z 32 32   $< --out $@/icon_32x32.png
	sips -z 64 64   $< --out $@/icon_32x32@2x.png
	sips -z 128 128 $< --out $@/icon_128x128.png
	sips -z 256 256 $< --out $@/icon_128x128@2x.png
	sips -z 256 256 $< --out $@/icon_256x256.png
	sips -z 512 512 $< --out $@/icon_256x256@2x.png
	sips -z 512 512 $< --out $@/icon_512x512.png
	cp              $<       $@/icon_512x512@2x.png

clean:
	rm -rf dosbox-staging.iconset
	rm -f icon_*.png