defmodule SecretVault.Cipher do
  @moduledoc """
  Provides an interface to implement encryption methods.
  """

  @typedoc """
  A key for symetric encryption algorithm as a binary.
  """
  @type key :: binary()

  @typedoc """
  Binary blob that contains encrypted data.
  """
  @type cypher_text :: binary()

  @typedoc """
  Binary blob that contains decrypted data.
  """
  @type plain_text :: binary()

  @doc """
  Encrypt the `plain_text` with the `key`.
  """
  @callback encrypt(key, plain_text, opts) :: cypher_text
            when opts: Keyword.t()

  @doc """
  Decrypt the `cypher_text` with the `key` used to get it.
  """
  @callback decrypt(key, cypher_text, opts) :: plain_text
            when opts: Keyword.t()

  @spec pack(cipher :: String.t(), [property :: String.t()]) :: binary()
  def pack(cipher, properties) when is_binary(cipher) and is_list(properties) do
    properties
    |> Enum.map(&Base.encode16/1)
    |> List.insert_at(0, cipher)
    |> Enum.join(";")
  end

  @spec unpack(binary()) ::
          {:ok, cipher :: String.t(), [property :: String.t()]}
          | {:error, reason :: atom()}
  def unpack(binary) when is_binary(binary) do
    case String.split(binary, ";") do
      [cipher | properties] ->
        properties = Enum.map(properties, &Base.decode16!/1)
        {:ok, cipher, properties}

      _ ->
        {:error, :no_codec}
    end
  rescue
    ArgumentError -> {:error, :bad_base16}
  end
end
