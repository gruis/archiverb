RubyArchiverb provides a Ruby bindings for creating
[tar](http://en.wikipedia.org/wiki/Tar_(computing) and
[ar](http://en.wikipedia.org/wiki/Ar_(Unix)) archives in memory.

## Install

``gem install archiverb``

## Use

```ruby
require "archiverb/ar"
require "archiverb/tar"
```

## Adding files from the file system

```ruby
archive  = Archiverb::Ar.new(File.expand_path("../henryIV.ar", __FILE__))
archive.add(File.expand_path("../spec/data/heneryIV.txt", __FILE__))
archive.add(File.expand_path("../spec/data/heneryIV-westmoreland.txt", __FILE__))

# archive will be written to henryIV.ar
archive.write 
```

## Read an archive from the file system

```ruby
archive  = Archiverb::Ar.new(File.expand_path("../henryIV.ar", __FILE__))
archive.read 

archive.files
```

## Adding files from memory 

```ruby
archive  = Archiverb::Ar.new(File.expand_path("../henryIV.ar", __FILE__))

contents = IO.read((File.expand_path("../spec/data/heneryIV.txt", __FILE__)))
archive.add("henryIV.txt", contents)

contents = IO.read((File.expand_path("../spec/data/heneryIV-westmoreland.txt", __FILE__)))
archive.add("henryIV-westmoreland.txt", contents)

archive.write 
```


```ruby
archive  = Archiverb::Tar.new(File.expand_path("../henryIV.ar", __FILE__))

archive.add("data/", contents)

contents = IO.read((File.expand_path("../spec/data/heneryIV.txt", __FILE__)))
archive.add("data/henryIV.txt", contents)

contents = IO.read((File.ebpand_path("../spec/data/heneryIV-westmoreland.txt", __FILE__)))
archive.add("data/henryIV-westmoreland.txt", contents)

archive.write 
```

## Using Archiverb with GZip
