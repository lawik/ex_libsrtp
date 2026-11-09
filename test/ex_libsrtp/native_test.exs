defmodule ExLibSRTP.NativeTest do
  use ExUnit.Case

  alias ExLibSRTP.Native

  test "creates successfully" do
    native = Native.create()
    assert is_reference(native)
  end

  test "releases sessions that are no longer referenced" do
    # The state destructor runs only when the reference is garbage collected,
    # so create sessions in a throwaway process and collect it
    task =
      Task.async(fn ->
        for _i <- 1..1_000 do
          native = Native.create()
          assert is_reference(native)
        end

        :erlang.garbage_collect()
        :ok
      end)

    assert :ok = Task.await(task)

    # Give the destructors a chance to run and make sure the VM survived them
    Process.sleep(100)
    assert is_reference(Native.create())
  end

  test "adds and removes stream successfully" do
    ssrc = 123_456_789

    native = Native.create()

    assert :ok ==
             Native.add_stream(
               native,
               1,
               ssrc,
               [
                 <<1, 2, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                   0, 0, 0, 0>>
               ],
               [],
               :rtp_default,
               :rtcp_default,
               0,
               false
             )

    assert :ok == Native.remove_stream(native, ssrc)
  end

  test "updates stream successfully" do
    ssrc = 123_456_789

    native = Native.create()

    assert :ok ==
             Native.add_stream(
               native,
               1,
               ssrc,
               [
                 <<1, 2, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                   0, 0, 0, 0>>
               ],
               [],
               :rtp_default,
               :rtcp_default,
               0,
               false
             )

    assert :ok ==
             Native.update(
               native,
               1,
               ssrc,
               [
                 <<14, 51, 84, 241, 9, 172, 84, 201, 217, 97, 188, 6, 111, 0, 234, 162, 196, 41,
                   66, 190, 185, 135, 28, 183, 160, 103, 53, 219, 225, 43>>
               ],
               [],
               :rtp_default,
               :rtcp_default,
               0,
               false
             )
  end
end
