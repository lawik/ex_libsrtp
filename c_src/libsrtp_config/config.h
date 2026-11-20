/*
 * Hand-written replacement for the config.h that libsrtp's configure/CMake
 * would generate (see config_in_cmake.h upstream), for the vendored
 * libsrtp 2.7.0 in c_src/libsrtp built with the OpenSSL crypto backend.
 *
 * Supported targets: Linux (glibc/musl) and macOS, 32- or 64-bit, little- or
 * big-endian. Anything arch-dependent is derived from compiler-predefined
 * macros instead of being probed, so the same file works when
 * cross-compiling.
 */
#ifndef EX_LIBSRTP_LIBSRTP_CONFIG_H
#define EX_LIBSRTP_LIBSRTP_CONFIG_H

#if !defined(__linux__) && !defined(__APPLE__)
#error "vendored libsrtp config.h only covers Linux and macOS"
#endif

#define PACKAGE_VERSION "2.7.0"
#define PACKAGE_STRING "libsrtp2 2.7.0"

/* Crypto backend: OpenSSL's libcrypto, which also provides AES-GCM. */
#define OPENSSL 1
#define GCM 1

/*
 * Logging: no debug logging, and no stdout/file sink. libsrtp then only
 * reports through a handler installed with srtp_install_err_report_handler(),
 * which the NIF doesn't do, so nothing is ever written to the BEAM's stdio.
 */
/* #undef ENABLE_DEBUG_LOGGING */
/* #undef ERR_REPORTING_STDOUT */
/* #undef ERR_REPORTING_FILE */

/* Byte order. libsrtp's RTP/RTCP header bitfields depend on this. */
#if !defined(__BYTE_ORDER__) || !defined(__ORDER_BIG_ENDIAN__)
#error "compiler does not define __BYTE_ORDER__, cannot configure libsrtp"
#endif
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#define WORDS_BIGENDIAN 1
#endif

/*
 * Same classification as libsrtp's configure.ac. Only affects the internal
 * AES implementation (crypto/cipher/aes.c), which the OpenSSL build doesn't
 * compile, but kept correct so switching backends doesn't silently misbuild.
 */
#if defined(__i386__) || defined(__x86_64__)
#define CPU_CISC 1
#define HAVE_X86 1
#else
#define CPU_RISC 1
#endif

/* Headers. */
#define HAVE_ARPA_INET_H 1
#define HAVE_INTTYPES_H 1
#define HAVE_NETINET_IN_H 1
#define HAVE_STDINT_H 1
#define HAVE_STDLIB_H 1
#define HAVE_SYS_SOCKET_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_UNISTD_H 1
#if defined(__linux__)
/* glibc and musl; on macOS datatypes.h uses <libkern/OSByteOrder.h>. */
#define HAVE_BYTESWAP_H 1
#endif
/* #undef HAVE_MACHINE_TYPES_H */
/* #undef HAVE_SYS_INT_TYPES_H */
/* #undef HAVE_WINDOWS_H */
/* #undef HAVE_WINSOCK2_H */

/* Functions (only used by libsrtp's test programs, which aren't built). */
#define HAVE_INET_ATON 1
#define HAVE_INET_PTON 1
#define HAVE_SIGACTION 1
#define HAVE_USLEEP 1

/* Fixed-width integer types, all from <stdint.h>. */
#define HAVE_UINT8_T 1
#define HAVE_UINT16_T 1
#define HAVE_UINT32_T 1
#define HAVE_UINT64_T 1
#define HAVE_INT32_T 1

/* 4 on armv7 (ILP32), 8 on arm64/x86_64 (LP64). */
#define SIZEOF_UNSIGNED_LONG __SIZEOF_LONG__
#define SIZEOF_UNSIGNED_LONG_LONG __SIZEOF_LONG_LONG__

#define HAVE_INLINE 1

/*
 * Left undefined, as upstream's configure and CMake builds do: with it
 * undefined v128_copy_octet_string() always copies byte-wise.
 */
/* #undef ALIGNMENT_32BIT_REQUIRED */

/* #undef OPENSSL_KDF */

#endif /* EX_LIBSRTP_LIBSRTP_CONFIG_H */
