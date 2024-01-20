defmodule WildriftNewsFeed.Feed do
  require Logger

  @base "https://wildrift.leagueoflegends.com"

  def fetch(lang) do
    url =
      "https://wildrift.leagueoflegends.com/page-data/#{lang}/news/game-updates/page-data.json"

    with {:ok, %{status_code: 200, body: body}} <- HTTPoison.get(url),
         {:ok, json} <- Poison.decode(body),
         articles <- get_in(json, ["result", "data", "allContentstackArticles", "nodes"]) do
      items = articles |> Enum.map(&article_to_xml_structure(&1, lang))

      feed =
        {:rss, %{version: "2.0"},
         [
           {:channel, nil,
            [
              {:title, nil, "WildRift news feed (#{lang})"},
              {:description, nil, "Feed generated from scraped JSON"},
              {:link, nil, "https://wildrift.leagueoflegends.com/en-us/news/game-updates/"}
            ] ++ items}
         ]}

      feed |> XmlBuilder.document() |> XmlBuilder.generate()
    else
      {:ok, %{status_code: 200, body: body}} ->
        {:content_error, body}

      {:ok, %{status_code: error_code}} ->
        {:error, {:http_error, error_code}}

      other = {:error, _} ->
        other
    end
  end

  def article_to_xml_structure(json, lang) do
    %{
      "id" => guid,
      "title" => title,
      "authorsField" => authors,
      "date" => date,
      "description" => description,
      "articleType" => article_type,
      "tags" => tags
    } = json

    url =
      case article_type do
        "Youtube" ->
          json |> Map.get("youtubeLink")

        _ ->
          link = json |> get_in(["link", "url"])
          "#{@base}/#{lang}#{link}"
      end

    author =
      with [%{"title" => author}] <- authors do
        author
      else
        _ -> nil
      end

    rss_date =
      with {:ok, parsed_date} <- Timex.parse(date, "{RFC3339}"),
           with_timezone <- Timex.to_datetime(parsed_date, "UTC"),
           {:ok, formatted_date} <- Timex.format(with_timezone, "{RFC822}") do
        formatted_date
      else
        err ->
          IO.puts("error: #{inspect(err)}")
          date
      end

    image =
      with %{"featuredImage" => %{"banner" => %{"url" => image_url}}} <- json,
           [image_type] <- Regex.run(~r/\.([^\.]+)$/, image_url, capture: :all_but_first) do
        {:enclosure, %{url: image_url, type: "image/#{image_type}"}, nil}
      else
        _ -> []
      end

    categories =
      tags |> Enum.map(fn %{"title" => tag_title} -> {:category, nil, tag_title} end)

    {:item, nil,
     [
       {:guid, nil, guid},
       {:title, nil, title},
       {:link, nil, url},
       {:description, nil, description},
       {:author, nil, author},
       {:pubDate, nil, rss_date},
       image
     ] ++ categories}
  end
end
