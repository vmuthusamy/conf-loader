require 'conf/main'
require 'pp'


describe Loader do
  it 'throws exception when file is not found in path' do
    expect{Loader.load_config('../srv/settings.conf',['ubuntu','production'])}.to raise_error(RuntimeError)
  end

  let(:config) do
    Loader.load_config('srv/settings.conf',['ubuntu','production'])
  end

  let(:config_no_overrides) do
    Loader.load_config('srv/settings.conf',[])
  end

  it 'throws exception when invalid entry is present in conf file' do
    expect{Loader.load_config('srv/invalid-settings.conf',['ubuntu','production'])}.to raise_error{RuntimeError}

  end


  it 'has valid expected overridden properties' do
    expect(config.common.paid_users_size_limit).to eq(2147483648)
    expect(config.ftp.name).to eq("hello there, ftp uploading")
    expect(config.http.params).to eq(["array", "of", "values"])
    expect(config.ftp[:path]).to eq("/etc/var/uploads")
    expect(config.ftp).to eq name: "hello there, ftp uploading",
                             path: "/etc/var/uploads",
                             enabled: false

    expect(config.ftp.lastname).to eq nil
    expect(config.http.path).to eq("/srv/var/tmp")
    expect(config.http)
  end

  it 'has valid expected overridden properties' do
    expect(config_no_overrides.common.paid_users_size_limit).to eq(2147483648)
    expect(config_no_overrides.ftp.name).to eq("hello there, ftp uploading")
    expect(config_no_overrides.http.params).to eq(["array", "of", "values"])
    expect(config_no_overrides.ftp[:path]).to eq("/tmp/")
    expect(config_no_overrides.ftp).to eq name: "hello there, ftp uploading",
                             path: "/tmp/",
                             enabled: false

    expect(config_no_overrides.ftp.lastname).to eq nil
    expect(config_no_overrides.http.path).to eq("/tmp/")
  end



end