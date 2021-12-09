defmodule Scraper do
  @moduledoc """
  Documentation for `Scraper`. A basic web scraping application that utilizes HTTPoison to
  """

  @doc """
  Hello world.

  ## Examples

      iex> Scraper.hello()
      :world

  """

  @spec get_response(binary) :: any
  def get_response(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found :(")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
    end
  end

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
      |> String.trim()

    review_tail =
      Floki.find(review, ".review-whole")
      |> Floki.text()
      |> String.trim()

    "#{review_head} #{review_tail}"
  end

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
            ind_rating == 0 ->
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
  end

  def get_review_stars(value) do
    cond do
      value == "10" -> ""
      value == "20" -> "**"
      value == "30" -> "***"
      value == "40" -> "****"
      value == "50" -> "*****"
      true -> 0
    end
  end

  def get_review_score(content, positive_words) do
    positive_words
    |> Enum.map(fn x ->
      if String.contains?(content, x) == true do
        1
      else
        0
      end
    end)
    |> Enum.sum()
  end

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

  @spec get_review_content(binary) :: list
  def get_review_content(url) do
    positive_words = get_list(Path.absname("lib/positive-words.txt"))

    {:ok, body} = Scraper.get_response(url)
    {:ok, html} = Floki.parse_document(body)

    reviews =
      html
      |> Floki.find("div.review-entry")
      |> Enum.map(fn review ->
        review_body = Scraper.get_review_body(review)
        review_user = Scraper.get_review_user(review)
        rating = List.first(Scraper.get_review_ratings(review))

        {customer_service, _} = List.pop_at(rating, 0)
        {friendliness, _} = List.pop_at(rating, 1)
        {pricing, _} = List.pop_at(rating, 2)
        {overall_experience, _} = List.pop_at(rating, 3)
        {recommend_dealer, _} = List.pop_at(rating, 4)
        score = Scraper.get_review_score(review_body, positive_words)

        %{
          body: review_body,
          user: review_user,
          customer_service: customer_service,
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

  def get_reviews(page) do
    base_url =
      "https://www.dealerrater.com/dealer/McKaig-Chevrolet-Buick-A-Dealer-For-The-People-dealer-reviews-23685/page"

    top_reviews =
      Enum.map(1..page, fn x -> Scraper.get_review_content("#{base_url}#{x}") end)
      |> List.flatten()
      |> Enum.sort_by(& &1.score)
      |> Enum.take(-3)

    {:ok, top_reviews}
  end

  def main do
    IO.puts(
      "Please wait while we uncover the worst offenders of overly positive reviews for the following dealer:\n -----{ McKaig Chevrolet Buick }-----"
    )

    Scraper.get_reviews(5)
    |> display_reviews()
  end

  def display_reviews({_, reviews}) do
    reviews
    |> Enum.map(fn r ->
      IO.puts("User: #{r.user}")
      IO.puts("Review: #{r.body}")
      IO.puts("Customer Service: #{r.customer_service}")
      IO.puts("Friendliness #{r.friendliness}")
      IO.puts("Pricing #{r.pricing}")
      IO.puts("Overall Experience:  #{r.overall_experience}")
      IO.puts("Recommend Dealer:  #{r.recommend_dealer}")
      IO.puts("\n")
    end)
  end
end
