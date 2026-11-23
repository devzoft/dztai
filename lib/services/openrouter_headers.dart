Map<String, String> openRouterHeaders(
  String key, {
  String accept = 'application/json',
}) => {
  'Authorization': 'Bearer $key',
  'Content-Type': 'application/json',
  'HTTP-Referer': 'https://devzoft.ai',
  'X-Title': 'DevZoft AI',
  'Accept': accept,
};
