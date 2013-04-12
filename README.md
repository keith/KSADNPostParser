# KSADNPostParser

This is a simpleish library for parsing [Markdown](http://daringfireball.net/projects/markdown/) flavored URLs. I created it to work with the [ADN API](http://developers.app.net/) but I guess it could be altered to work elsewhere.

[![Build Status](https://travis-ci.org/Keithbsmiley/KSADNPostParser.png?branch=master)](https://travis-ci.org/Keithbsmiley/KSADNPostParser)

## Usage

Import `KSADNPostParser.h` into your project. This library relies on you having some global keys definied for various dictionary keys. This can be seen in `KSContants` in the Example project. If you would like to run the tests in the Example project run `./setup.sh` from the root directory. You can look in the tests for some example usage. `KSADNPostParser.h` is also well documented.

```
[[KSADNPostParser shared] postDictionaryForText:post withBlock:^(NSDictionary *dictionary, NSError *error) {
  // Handle error or use dictionary with post
}];
```
