#!/bin/bash

jison fol.jison

mocha --compilers coffee:coffee-script/register;

mocha parser/test/ --compilers coffee:coffee-script/register;

mocha proofs/test/ --compilers coffee:coffee-script/register;


