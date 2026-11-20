defmodule ExLibSRTP.GCMTest do
  # libsrtp only has AES-GCM when built with an external crypto backend
  # (OpenSSL here), so these fail against an internal-crypto libsrtp.
  use ExUnit.Case, async: true

  alias ExLibSRTP.Policy

  # Vectors from libsrtp's own srtp_validate_gcm() (test/srtp_driver.c):
  # AEAD_AES_128_GCM with a 16-byte key and 12-byte salt.
  @gcm_128_key <<0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C,
                 0x0D, 0x0E, 0x0F, 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9,
                 0xAA, 0xAB>>
  @ssrc 0xCAFEBABE

  @rtp <<0x80, 0x0F, 0x12, 0x34, 0xDE, 0xCA, 0xFB, 0xAD, 0xCA, 0xFE, 0xBA, 0xBE>> <>
         :binary.copy(<<0xAB>>, 16)
  @srtp <<0x80, 0x0F, 0x12, 0x34, 0xDE, 0xCA, 0xFB, 0xAD, 0xCA, 0xFE, 0xBA, 0xBE, 0xC5, 0x00,
          0x2E, 0xDE, 0x04, 0xCF, 0xDD, 0x2E, 0xB9, 0x11, 0x59, 0xE0, 0x88, 0x0A, 0xA0, 0x6E,
          0xD2, 0x97, 0x68, 0x26, 0xF7, 0x96, 0xB2, 0x01, 0xDF, 0x31, 0x31, 0xA1, 0x27, 0xE8,
          0xA3, 0x92>>

  @rtcp <<0x81, 0xC8, 0x00, 0x0B, 0xCA, 0xFE, 0xBA, 0xBE>> <> :binary.copy(<<0xAB>>, 16)
  @srtcp <<0x81, 0xC8, 0x00, 0x0B, 0xCA, 0xFE, 0xBA, 0xBE, 0xC9, 0x8B, 0x8B, 0x5D, 0xF0, 0x39,
           0x2A, 0x55, 0x85, 0x2B, 0x6C, 0x21, 0xAC, 0x8E, 0x70, 0x25, 0xC5, 0x2C, 0x6F, 0xBE,
           0xA2, 0xB3, 0xB4, 0x46, 0xEA, 0x31, 0x12, 0x3B, 0xA8, 0x8C, 0xE6, 0x1E, 0x80, 0x00,
           0x00, 0x01>>

  defp session(profile, key) do
    srtp = ExLibSRTP.new()
    policy = %Policy{ssrc: @ssrc, key: key, rtp: profile, rtcp: profile}
    :ok = ExLibSRTP.add_stream(srtp, policy)
    srtp
  end

  test "SRTP_AEAD_AES_128_GCM matches libsrtp's reference vectors" do
    # DTLS-SRTP protection profile 0x0007, as negotiated by ex_dtls.
    assert {:ok, profile} = Policy.crypto_profile_from_dtls_srtp_protection_profile(0x07)
    assert profile == :aes_gcm_128_16_auth

    sender = session(profile, @gcm_128_key)
    assert {:ok, @srtp} = ExLibSRTP.protect(sender, @rtp)
    assert {:ok, @srtcp} = ExLibSRTP.protect_rtcp(sender, @rtcp)

    receiver = session(profile, @gcm_128_key)
    assert {:ok, @rtp} = ExLibSRTP.unprotect(receiver, @srtp)
    assert {:ok, @rtcp} = ExLibSRTP.unprotect_rtcp(receiver, @srtcp)
  end

  test "SRTP_AEAD_AES_256_GCM round-trips and rejects tampered packets" do
    # DTLS-SRTP protection profile 0x0008: 32-byte key, 12-byte salt.
    assert {:ok, profile} = Policy.crypto_profile_from_dtls_srtp_protection_profile(0x08)
    key = :binary.copy(<<0x5A>>, 44)

    sender = session(profile, key)
    receiver = session(profile, key)

    assert {:ok, protected} = ExLibSRTP.protect(sender, @rtp)
    assert byte_size(protected) == byte_size(@rtp) + 16

    <<header::binary-size(12), first, rest::binary>> = protected
    tampered = <<header::binary, Bitwise.bxor(first, 1), rest::binary>>
    assert {:error, :auth_fail} = ExLibSRTP.unprotect(receiver, tampered)
    assert {:ok, @rtp} = ExLibSRTP.unprotect(receiver, protected)

    assert {:ok, protected_rtcp} = ExLibSRTP.protect_rtcp(sender, @rtcp)
    assert {:ok, @rtcp} = ExLibSRTP.unprotect_rtcp(receiver, protected_rtcp)
  end
end
