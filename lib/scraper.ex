defmodule Scraper do
  @moduledoc """
  Documentation for `Scraper`. A basic web scraping application that utilizes HTTPoison to fetch pages from a website and Forki to parse HTML.
  """

  @doc """
  Using HTTPoison, goes out and fetch the page we will be processing. If status code is 200, return pars. If we receive a 404, it means the function was unable to retrieve any data.

  ## Examples

      iex> url = "https://www.dealerrater.com/dealer/Mark-Miller-Subaru-Midtown-dealer-reviews-8951/page2"
      iex> Scraper.get_response(url)
  """

  @spec get_response(binary) :: any
  def get_response(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Floki.parse_document(body)

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found :(")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
    end
  end

  @doc """

   Traverse down to retrieve the review body from the HTML. The review body is split in two : the review's beginning has the .review-tiltle selector and the tail has the .review-whole selector.

  ## Examples

      iex> {:ok, html} = Floki.parse_document("<p><span class=review-title>Jesse was great</span><span class=review-title> and we will be coming back!</span></p>")
      iex> Scraper.get_review_body(html)
      "Jesse was great and we will be coming back!"

  """
  @spec get_review_body(
          binary
          | [
              binary
              | {:comment, binary}
              | {:pi | binary, binary | [{any, any}], list}
              | {:doctype, binary, binary, binary}
            ]
        ) :: nonempty_binary

  def get_review_body(review) do
    review_head =
      Floki.find(review, ".review-title")
      |> Floki.text()

    review_tail =
      Floki.find(review, ".review-whole")
      |> Floki.text()

    review_body = "#{review_head}#{review_tail}"
    String.trim(review_body)
  end

  @doc """

   Traverse down the HTML and retrieve user of the review. Remove the by from the value.

  ## Examples

      iex> html = Floki.parse_document("<p><span class=review-title>Jesse was great</span><span class=review-title> and we will be coming back</span></p>")
      iex> Scraper.get_review_body(html)



  """
  @spec get_review_user(
          binary
          | [
              binary
              | {:comment, binary}
              | {:pi | binary, binary | [{any, any}], list}
              | {:doctype, binary, binary, binary}
            ]
        ) :: binary
  def get_review_user(review) do
    Floki.find(review, "span.italic.font-16.bolder.notranslate")
    |> Floki.text()
    |> String.replace("by ", "")
  end

  @doc """

   receive a rating and return the stars

  ## Examples

      iex> Scraper.get_review_stars("10")
      "*"
  """
  def get_review_stars(value) do
    cond do
      value == "10" -> "*"
      value == "20" -> "**"
      value == "30" -> "***"
      value == "40" -> "****"
      value == "50" -> "*****"
      true -> 0
    end
  end

  @doc """

   Traverse down the HTML to find each individual ratings that belongs to the review. If the rating is , assign the children attribute "Yes" or "No" for Recommnend Dealer attribute.

  """
  def get_review_ratings(review) do
    Floki.find(review, ".review-ratings-all")
    |> Enum.map(fn rating ->
      Floki.find(rating, ".tr")
      |> Enum.map(fn ind_ratings ->
        ind_rating =
          Floki.find(ind_ratings, "div.rating-static-indv")
          |> Floki.attribute("class")
          |> Enum.map(fn x -> String.replace(x, ~r/[^\d]/, "") end)
          |> Enum.map(fn x -> Scraper.get_review_stars(x) end)
          |> List.first(0)

        ind_rating =
          cond do
            ind_rating === 0 ->
              ind_ratings
              |> Floki.find("div.td.small-text.boldest")
              |> Floki.text()
              |> String.trim()

            true ->
              ind_rating
          end

        ind_rating
      end)
    end)
    |> List.flatten()
  end

  @doc """

   Calculate a review score based on the number of matches to a positive word dictionary file.


  ## Examples

      iex> pos_words = ["great", "awesome", "amazing"]
      iex> content = "Bob was absolutely Amazing! Great service as always"
      iex> Scraper.get_review_score(content, pos_words)
      2

  """
  def get_review_score(content, pos_words_arr) do
    content = String.downcase(content)

    pos_words_arr
    |> Enum.map(fn x ->
      if String.contains?(content, x) == true do
        1
      else
        0
      end
    end)
    |> Enum.sum()
  end

  @doc """

   Receive a path for a file and returns a map af strings.

  ## Examples

      iex> path = Path.absname("files/word-example.txt")
      iex> Scraper.get_list(path)
      ["zenith", "zest", "zippy"]

  """
  @spec get_list(
          binary
          | maybe_improper_list(
              binary | maybe_improper_list(any, binary | []) | char,
              binary | []
            )
        ) :: list
  def get_list(path) do
    File.stream!(path)
    |> Enum.map(fn x -> String.trim(x) end)
  end

  @doc """

   Receive a url and return all reviews.

  """
  @spec get_review_content(binary) :: list
  def get_review_content(url) do
    positive_words = get_list(Path.absname("lib/positive-words.txt"))

    {:ok, html} = Scraper.get_response(url)

    reviews =
      html
      |> Floki.find("div.review-entry")
      |> Enum.map(fn review ->
        review_body = Scraper.get_review_body(review)
        review_user = Scraper.get_review_user(review)
        rating = Scraper.get_review_ratings(review)

        {customer_service, _} = List.pop_at(rating, 0)
        {quality_of_work, _} = List.pop_at(rating, 1)
        {friendliness, _} = List.pop_at(rating, 2)
        {pricing, _} = List.pop_at(rating, 3)
        {overall_experience, _} = List.pop_at(rating, 4)
        {recommend_dealer, _} = List.pop_at(rating, 5)
        score = Scraper.get_review_score(review_body, positive_words)

        %{
          body: review_body,
          user: review_user,
          customer_service: customer_service,
          quality_of_work: quality_of_work,
          friendliness: friendliness,
          pricing: pricing,
          overall_experience: overall_experience,
          recommend_dealer: recommend_dealer,
          score: score
        }
      end)

    {:ok, reviews}

    reviews
  end

  @doc """

    Receive a number of pages and conglomerate all reviews into one single map. Sort the map by the review's score and return the top three overly positive reviews.

  """
  def get_top_reviews(page) do
    base_url =
      "https://www.dealerrater.com/dealer/McKaig-Chevrolet-Buick-A-Dealer-For-The-People-dealer-reviews-23685"

    top_reviews =
      Enum.map(1..page, fn x -> Scraper.get_review_content("#{base_url}/page#{x}") end)
      |> List.flatten()
      |> Enum.sort_by(& &1.score)
      |> Enum.take(-3)

    {:ok, top_reviews}
  end

  @doc """

    Main function to retrieve top three reviews from 5 pages and display them.
  """
  def main do
    IO.puts(
      "Please wait while we uncover the worst offenders of overly positive reviews for the following dealer:\n -----{ McKaig Chevrolet Buick }-----"
    )

    Scraper.get_top_reviews(5)
    |> display_reviews()
  end

  @doc """

   Write reviews to the console.

  """

  def display_reviews({_, reviews}) do
    reviews
    |> Enum.map(fn r ->
      IO.puts("User: #{r.user}")
      IO.puts("Review: #{r.body}")
      IO.puts("Customer Service: #{r.customer_service}")
      IO.puts("Quality of Work: #{r.quality_of_work}")
      IO.puts("Friendliness #{r.friendliness}")
      IO.puts("Pricing #{r.pricing}")
      IO.puts("Overall Experience:  #{r.overall_experience}")
      IO.puts("Recommend Dealer:  #{r.recommend_dealer}")
      IO.puts("\n")
    end)
  end
end
