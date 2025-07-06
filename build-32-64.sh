./iSSH2.sh --platform=iphoneos --min-version=8.0 --archs="arm64 arm64e armv7 armv7s x86_64"
lipo -info ./openssl_iphoneos/lib/libssl.a

