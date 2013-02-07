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

archive.names # => ["heneryIV.txt", "heneryIV-westmoreland.txt"] 
archive.files # => [#<Archiverb::File:0x007f8d7b90acf8 @name="heneryIV.txt" ... >, ...]
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
archive  = Archiverb::Tar.new(File.expand_path("../henryIV.tar", __FILE__))

archive.add("data/", :mode => 0744)

contents = IO.read((File.expand_path("../spec/data/heneryIV.txt", __FILE__)))
archive.add("data/henryIV.txt", contents)

contents = IO.read((File.expand_path("../spec/data/heneryIV-westmoreland.txt", __FILE__)))
archive.add("data/henryIV-westmoreland.txt", contents)

archive.write 
```
