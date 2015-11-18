defmodule PubKeys.Helper do

  @doc """
  returns path "example_auth_keys_files" if argument is :test.
  Otherwise returns a path to .ssh_keys directory in your home/username directory, for example: "/home/git/.ssh_keys".
  ## Examples
      iex> PubKeys.Helper.files_path(:test)
      "example_auth_keys_files/"
  """
  def files_path(:test), do: "example_auth_keys_files/"
  def files_path(_) do
    local_user = elem(System.cmd("whoami", []), 0) |> String.strip
    "/home/#{local_user}/.ssh_keys"
  end

  @doc """
  Checks if given argument is an empty string.
  ## Examples
      iex> PubKeys.Helper.empty?("")
      true
      iex> PubKeys.Helper.empty?("apple")
      false
  """
  def empty?(""), do: true
  def empty?(x) when is_binary(x), do: false

  @doc """
  Given a list and a string, checks if the list contains the specified string
  ## Examples
      iex> PubKeys.Helper.contains?([], "apple")
      false
      iex> PubKeys.Helper.contains?(["apple", "banana", "orange"], "apple")
      true
  """
  def contains?([], _), do: false
  def contains?([x | _], x), do: true
  def contains?([_head | tail], x), do: contains?(tail, x)

  @doc """
  Given an input of ssh_key string in format like `ssh-rsa My_unique_key john@test123`, returns the main unique key
  ## Examples
      iex> PubKeys.Helper.parse_key("ssh-rsa My_unique_key john@test123")
      "My_unique_key"
  """
  def parse_key(ssh_key) do
    String.split(ssh_key, " ") |> Enum.at(1)
  end

  @doc """
  Given a tuple containing ip address and a list of keys, a target ssh key, and action, returns false if the list of keys does not contain the target key and the action is :add or if the list of keys contains the target key and the action is :remove. Otherwise, returns true.
  ## Examples
      iex> path = PubKeys.Helper.files_path(:test)
      iex> file_keys = PubKeys.read_keys("112.3.44.555", path)
      iex> PubKeys.Helper.should_skip?(file_keys, "ssh-rsa XXX123YZA john@test", :add)
      false
      iex> PubKeys.Helper.should_skip?(file_keys, "ssh-rsa ABCD123abcd john@test", :add)
      true
      iex> PubKeys.Helper.should_skip?(file_keys, "ssh-rsa ABCD123abcd john@test", :remove)
      false
      iex> PubKeys.Helper.should_skip?(file_keys, "ssh-rsa XXX123YZA john@test", :remove)
      true
  """
  def should_skip?({ip, filtered_keys}, key, action \\ :add) do
    stripped_keys = Enum.map(filtered_keys, &parse_key/1)
    parsed_key    = parse_key(key)

    case {contains?(stripped_keys, parsed_key), action} do
      {false, :add} -> false
      {true, :remove} -> false
      _ -> IO.puts "#{ip} - Skipping"
           true
    end
  end

end
