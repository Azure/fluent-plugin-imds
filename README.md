# fluent-plugin-imds

[Fluentd](https://fluentd.org/) filter plugin to add Azure metadata to logs.

Fluentd filter plugin to add Azure metadata to logs.

## Installation


### Gem Install

```
Follow the instructions in the packages section of this repo

*Not available on RubyGems
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-imds"
```

And then execute:

```
$ bundle
```

## Configuration

Sample Configuration:

<filter tag>
  @type imds
</filter>

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
