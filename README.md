Archiverb provides Ruby bindings for creating
[tar](http://en.wikipedia.org/wiki/Tar_(computing)) and
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

## Working with Gzip Files

### Writing to a Gzip file

To create a gzipped tar archive, populate a ``Archiverb::Tar`` object in
memory then create a ``GzipWriter`` object and pass it to
``Archiverb::Tar#write``.

```ruby
require "zlib"

path    = File.expand_path("../henryIV.tar", __FILE__)

archive = Archiverb::Tar.new
archive.add("data/henryIV.txt", 
            IO.read((File.expand_path("../spec/data/heneryIV.txt", __FILE__))))
archive.add("data/henryIV-westmoreland.txt", 
            IO.read((File.expand_path("../spec/data/heneryIV-westmoreland.txt", __FILE__))))

Zlib::GzipWriter.open(path) do |gz|
  archive.write(gz)
end
```


### Reading from a Gzip file

```ruby
require "zlib"

File.open(File.expand_path("../henryIV.tgz", __FILE__)) do |f|
  gz      = Zlib::GzipReader.new(f)
  archive = Archiverb::Tar.new(gz)
  archive.read
  archive.names # => ["data/henryIV.txt", "data/henryIV-westmoreland.txt"] 
end
```
