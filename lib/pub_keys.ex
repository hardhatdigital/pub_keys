defmodule PubKeys do
  import PubKeys.Helper

  @remote_user Application.get_env(:pub_keys, :remote_user)
  @remote_auth_keys_path Application.get_env(:pub_keys, :remote_auth_keys_path)
  @instructions """
  To add key: elixir ssh_keys.exs --add "auth_key"
  To remove key: elixir ssh_keys.exs --remove "auth_key"
  To deploy all auth key files: elixir ssh_keys.exs --deploy-all
  """

  def output do
    IO.inspect @remote_user
    IO.inspect @remote_auth_keys_path
  end

  @moduledoc """
  This mix project uses an Elixir script to manage public keys from a git server. It can add and remove public keys from all targetted servers.

  - `pub_keys h` to get help
  - `pub_keys --add "key here"` to add key to all servers
  - `pub_keys --remove "key here"` to remove key from all servers
  - `pub_keys --deploy-all` to push out auth_keys files to all servers (if you want to add a key to files manually, for example)
  """
  def main(options) do
   
    path = files_path(Mix.evn)

    files_list = System.cmd("ls", [path]) |> elem(0) |> String.split("\n")
    
    case options do
      ["h"] -> IO.puts @instructions
      ["--deploy-all"] -> deploy_all(files_list, path)
      ["--add", ssh_key] -> add_user_key(ssh_key, files_list, path)
      ["--remove", ssh_key] -> remove_user_key(ssh_key, files_list, path)
      _ -> IO.puts "Unrecognized input.\n#{@instructions}"
    end
  end
 
  @doc """
  Given an input of remote server's IP address, and the directory path to ssh key files, returns a tuple containing the ip address and a list of the ssh_keys
  ## Examples
      iex> path = PubKeys.Helper.files_path(:test)
      iex> PubKeys.read_keys("192.168.0.10", path)
      {"192.168.0.10", ["ssh-rsa ABCD123abcd test1@work", "ssh-rsa XYZ987abcd test2@work"]}
  """
  def read_keys(ip, path) do
    {:ok, content} = File.read("#{path}/#{ip}")
    filtered_keys = (String.split(content, "\n") |> Enum.reject(&empty?/1))
    {ip, filtered_keys}
  end

  @doc """
  Given a list of ssh_keys files and the directory path of the files, this method will run `scp_to_server` to copy the ssh key file to each remote server as per the ip address in the file name, and overwrite the remote authorized keys file.
  """
  def deploy_all(files_list, path) do
    files_list
    |> Enum.reject(&empty?(&1))
    |> Enum.map(&scp_to_server(&1, path))
  end


  @doc """
  Prepend a key into the authorized_keys file if the key doesn't exist inside the file yet
  """
  def add_user_key(ssh_key, files_list, path) do
    files_list
    |> Enum.reject(&empty?(&1))
    |> Enum.map(&read_keys(&1, path))
    |> Enum.reject(&should_skip?(&1, ssh_key))
    |> Enum.map(&prepend_key(&1, ssh_key, path))
    |> Enum.map(&scp_to_server(&1, path))
  end

  @doc """
  Prepends a key inside the specified authorized_keys file
  """
  def prepend_key({file_path, _keys}, key, path) do
    {:ok, content} = File.read "#{path}/#{file_path}"
    new_content = "#{key}\n" <> content
    {:ok, file} = File.open "#{path}/#{file_path}", [:write]
    IO.binwrite file, new_content
    File.close file
    IO.puts "Successfully add key #{key} into #{file_path}"
    file_path
  end
  
  @doc """
  Remove a key in the authorized_keys file if it does not exist inside the file
  """
  def remove_user_key(ssh_key, files_list, path) do
    files_list
    |> Enum.reject(&empty?(&1))
    |> Enum.map(&read_keys(&1, path))
    |> Enum.reject(&should_skip?(&1, ssh_key, :remove))
    |> Enum.map(&remove_key(&1, ssh_key, path))
    |> Enum.map(&scp_to_server(&1, path))
  end

  @doc """
  Remove a key inside the specified authorized_keys file
  """
  def remove_key({file_path, _keys}, key, path) do
    {:ok, content} = File.read "#{path}/#{file_path}"
    parsed_key     = parse_key(key)

    new_content = String.split(content, "\n") 
                  |> Enum.filter(&(parse_key(&1) != parsed_key)) 
                  |> Enum.join("\n")
    {:ok, file} = File.open "#{path}/#{file_path}", [:write]
    IO.binwrite file, new_content
    File.close file
    IO.puts "Successfully remove key #{key} from #{file_path}"
    file_path
  end

  @doc """
  Given a file with IP Address as the name and the remote path where the authorized ssh keys are stored in the remote server. This method will run `scp` system command from the specified file to the path in the remote server where the IP Address file name indicates.
  """
  def scp_to_server(file, path) do
    {_response, code} = System.cmd("scp", ["-o StrictHostKeyChecking=no", "#{path}/#{file}", "#{@remote_user}@#{file}:#{@remote_auth_keys_path}"])
    case code do
      0 -> IO.puts "#{file} - Success"
      _ -> IO.puts "#{file} - FAILURE! Couldn't scp file"
    end
  end
end
