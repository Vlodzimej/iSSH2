./iSSH2.sh --platform=iphoneos --min-version=8.0 --archs="arm64 arm64e x86_64"
lipo -info ./libssh2_iphoneos/lib/libssh2.a
lipo -info ./openssl_iphoneos/lib/libcrypto.a
lipo -info ./openssl_iphoneos/lib/libssl.a
