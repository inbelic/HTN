# Bumped Talk

##Intro
Welcome to our project for Hack the North 2020!
The motivation behind our project was to provide a tool for those who have been impacted by visual impairment, either
adjecently or directly. Hack the North provided us with an opportunity to push ourselves to create a proof of concept for
an app, Bumped Talk, which would allow the user to take a photo of any braille text in any language and output the text
using text to speech, either online or offline!

In the time allocated to implement our solution, we were able to create a python library and julia 
script that takes in a photo of a braille character and outputs an .mp3 audio file of the words. Currently, we support 
english with most of the IETF accents, however our dictionary module is easily modifable to support any language you 
would like, as well as incorperating new puncuation.

## Requirements
- Install the following packages using pip3 install: gTTS
- Install the following packages using apt install: imageMagick

## Contribution Practices
- Before making any changes, create a branch off main
- Once you are ready to merge your changes in, create a PR
- Create a folder for your library under lib
- Experiment inside sandbox folder
- main.py will hold presentation code

## Examples
Please see the images folder for some sample images of braille chars, words and sentences. Their corresponding audio
outputs can be found in the recording folder.

## Instructions
To run the script follow these steps:
- Move to the directory where you are storing the repository
- From your terminal call python main.py "file_path_to/sample_input.png" "file_path_to/sample_output.mp3"
  - On line 18 of main.py you can change the accent to your desired IETF tag
 
