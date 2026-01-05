#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require

loader = Zeitwerk::Loader.new
loader.push_dir(__dir__)
loader.setup

require 'active_support'
require 'active_support/core_ext'

Board::PieceMoves.instance.calculate!

UciEngine.new.run
