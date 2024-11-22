import json
import os.path
import sys
import webbrowser
from subprocess import call
from sys import argv


def check_file_extension_and_open_file(file_to_open, text_editor="gedit"):
    """This function checks if the file-to-be-opened is actually a Google Docs (gdoc, gsheet, gslides, gdraw) file or not.
    If not, then the file is passed to the the text editor and gdocopener exits. (This is necessary, because Linux
    makes file
    associations
    based on file types and not on file extensions.) If it is indeed a Google Docs file, the function returns its
    contents."""

    _, extension = os.path.splitext(file_to_open)
    if extension not in [".gdoc", ".gsheet", ".gslides", ".gdraw", ".gtable", ".gform"]:
        print(
            "This was not a Google Docs file, so gdocopener passed it over to the text editor."
        )
        try:
            return call([text_editor, file_to_open])
        except FileNotFoundError:
            print("Could not run the text editor. Maybe not installed?")
        finally:
            sys.exit()

    try:
        with open(file_to_open) as file:
            return file.read()

    except FileNotFoundError:
        print("The Google Docs file you want to open does not exist!")
        sys.exit()


def extract_url_from_gdoc(gdoc_content):
    """This function parses the file contents. If it is not JSON, it notifies the user and exits. If it is JSON,
    extracts and returns the URL to the Docs file."""

    try:
        json_dict = json.loads(gdoc_content)
        return json_dict["url"]

    except json.JSONDecodeError:
        print(
            "The file you want to open is not a valid Google Docs file (aka JSON file)!"
        )
        sys.exit()


def open_url_in_chrome(gdoc_url):
    """This function takes the url of the gdoc file and opens it in the Chrome browser. The function chooses the
    appropriate command to start Chrome based on the user's current OS."""

    try:
        webbrowser.open_new_tab(gdoc_url)
    except webbrowser.Error:
        print("There was a problem with opening the url in the web browser.")
        sys.exit()


if __name__ == "__main__":
    number_of_arguments = len(argv)
    if number_of_arguments > 1:
        file_to_open = argv[1]

        # Set the preferred text editor, if given as second argument
        if number_of_arguments > 2:
            text_editor = argv[2]
        else:
            text_editor = "gedit"

        content = check_file_extension_and_open_file(
            file_to_open=file_to_open, text_editor=text_editor
        )
        gdoc_path = extract_url_from_gdoc(gdoc_content=content)
        open_url_in_chrome(gdoc_path)
    else:
        print(
            "You should pass a file as an argument to gdocopener!/n Usage: python gdocopener.py [filename]"
        )
