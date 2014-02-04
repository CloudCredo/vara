def unzip(source, destination)
  FileUtils.rm_rf(destination)
  FileUtils.mkdir_p(destination)
  FileUtils.cd(destination) do
    `unzip #{source}`
  end
end
