using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;

namespace NzbDrone.Core.Applications.Qui
{
    public class QuiIndexerResponse
    {
        [JsonProperty("torznab_indexer")]
        public QuiIndexer TorznabIndexer { get; set; }
    }

    public class QuiIndexer
    {
        [JsonProperty("id")]
        public int Id { get; set; }

        [JsonProperty("name")]
        public string Name { get; set; }

        [JsonProperty("base_url")]
        public string BaseUrl { get; set; }

        [JsonProperty("api_key")]
        public string ApiKey { get; set; }

        [JsonProperty("backend")]
        public string Backend { get; set; }

        [JsonProperty("enabled")]
        public bool Enabled { get; set; }

        [JsonProperty("priority")]
        public int Priority { get; set; }

        [JsonProperty("timeout_seconds")]
        public int TimeoutSeconds { get; set; }

        [JsonProperty("limit_default")]
        public int LimitDefault { get; set; }

        [JsonProperty("limit_max")]
        public int LimitMax { get; set; }

        [JsonProperty("indexer_id")]
        public string IndexerId { get; set; }

        [JsonProperty("capabilities")]
        public List<string> Capabilities { get; set; }

        [JsonProperty("categories")]
        public List<string> Categories { get; set; }

        public bool Equals(QuiIndexer other)
        {
            if (ReferenceEquals(null, other))
            {
                return false;
            }

            return other.BaseUrl == BaseUrl &&
                other.ApiKey == ApiKey &&
                other.Name == Name &&
                other.Enabled == Enabled &&
                other.Priority == Priority &&
                other.IndexerId == IndexerId &&
                other.Categories?.OrderBy(c => c).SequenceEqual(Categories?.OrderBy(c => c) ?? Enumerable.Empty<string>()) == true;
        }
    }
}
