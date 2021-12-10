# Scraper

**Scraper is simple application that scrapes the website https://www.dealerrater.com and get a list of overly positive reviews for the dealer McKaig Chevrolet Buick **

## Summary

This project is a simple application for me to have a better understanding of the capabilities of Elixir as a functional programming language. The projects scrapes the website Dealer Rater and receive a list of overly positive reviews for the dealer McKaig Chevrolet. The application uses two libraries, [HTTPoison](https://github.com/edgurgel/httpoison "HTTPoison") to fetch the pages and [Floki](https://github.com/philss/floki "Floki") to parse the HTML. We will traverse the HTML and find all fields related to a review and return them. A review score is calculated depending on how many instance of positive words are found. The application will then write the top three overly positive reviews to the console.

##Run the code locally

To run the code on your workstation, please do the following:

Install [Elixir](https://elixir-lang.org/install.html "Elixir")

Install [Github](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)""]

run the following command in your terminal 

`git clone github.com/randylvan/randy-van-scraper.git`

Navigate to the Scraper directory and run:

`mix deps.get`

You can use the Elixir interractive shell to use the application:

'iex -S mix'

To display the top overly positive reviews for the dealer McKaig Chevrolet Buick, run the following command inside Elixirs Interactive Environment:
`Scraper.main`

To test the project, run the following in your terminal
`mix test`

More documentation can be found inside the project. Run `mix docs` and open `/doc/index.html` in the browser of your choice.


