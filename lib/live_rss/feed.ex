defmodule LiveRSS.Feed do
  @moduledoc false
  alias LiveRSS.Feed

  defmodule Item do
    @moduledoc false
    @type t :: %__MODULE__{
            author: String.t(),
            source: String.t(),
            published: String.t(),
            title: String.t(),
            description: String.t(),
            link: String.t(),
            media: String.t()
          }
    defstruct [:published, :title, :description, :link, :media, author: nil, source: nil]

    @spec create(%{}) :: Item.t()
    def create(item) do
      %__MODULE__{
        author: item["author"],
        source: item["source"],
        published: item["pub_date"],
        title: item["title"],
        description: item["description"],
        link: item["link"],
        media:
          get_in(item, ["extensions", "media", "content"]) |> hd() |> get_in(["attrs", "url"])
      }
    end
  end

  @type t :: %__MODULE__{
          title: String.t(),
          description: String.t(),
          language: String.t(),
          items: [Item.t()]
        }
  defstruct [:title, :description, :language, :items]

  @spec create(%{}) :: Feed.t()
  def create(feed) do
    %__MODULE__{
      title: feed["title"],
      description: feed["description"],
      language: feed["language"],
      items: Enum.map(feed["items"], &Item.create(&1))
    }
  end
end
