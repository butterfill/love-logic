#!/bin/bash


mocha --compilers coffee:coffee-script/register;

mocha parser/test/ --compilers coffee:coffee-script/register;

mocha proofs/test/ --compilers coffee:coffee-script/register;


