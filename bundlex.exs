defmodule Membrane.ExLibSRTP.BundlexProject do
  use Bundlex.Project

  # libsrtp 2.7.0 (github.com/cisco/libsrtp, tag v2.7.0) is vendored in
  # c_src/libsrtp and compiled straight into the NIF with the OpenSSL backend,
  # configured by c_src/libsrtp_config/config.h. Only libcrypto is linked
  # dynamically.
  @libsrtp_sources ~w(
    srtp/srtp.c
    crypto/cipher/cipher.c
    crypto/cipher/cipher_test_cases.c
    crypto/cipher/null_cipher.c
    crypto/cipher/aes_icm_ossl.c
    crypto/cipher/aes_gcm_ossl.c
    crypto/hash/auth.c
    crypto/hash/auth_test_cases.c
    crypto/hash/null_auth.c
    crypto/hash/hmac_ossl.c
    crypto/kernel/alloc.c
    crypto/kernel/crypto_kernel.c
    crypto/kernel/err.c
    crypto/kernel/key.c
    crypto/math/datatypes.c
    crypto/replay/rdb.c
    crypto/replay/rdbx.c
  )

  def project do
    [
      natives: natives()
    ]
  end

  defp natives() do
    [
      srtp: [
        interface: :nif,
        sources:
          [
            "srtp.c",
            "srtp_util.c",
            "unifex_util.c"
          ] ++ Enum.map(@libsrtp_sources, &Path.join("../libsrtp", &1)),
        compiler_flags: libsrtp_compiler_flags(),
        os_deps: [libcrypto: :pkg_config],
        preprocessor: Unifex
      ]
    ]
  end

  # Passed as compiler flags rather than `includes` so they come before the
  # -I flags from pkg-config, and an installed libsrtp2 can never shadow the
  # vendored headers.
  defp libsrtp_compiler_flags() do
    c_src = Path.join(__DIR__, "c_src")

    include_flags =
      ["libsrtp_config", "libsrtp/include", "libsrtp/crypto/include"]
      |> Enum.map(&~s(-I"#{Path.join(c_src, &1)}"))

    include_flags ++ ["-DHAVE_CONFIG_H", "-fvisibility=hidden"]
  end
end
