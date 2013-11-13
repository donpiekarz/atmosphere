## List http mappings

Get a list of http mappings. A regular user is allowed to see only http mappings related to their own appliances. Administrator is able to see all http mappings by adding query parameter `all` set to `true`.

```
GET /http_mappings
```

```json
{
    "http_mappings": [
        {
            "id": 11,
            "application_protocol": "http",
            "url": "conn.ca",
            "appliance_id": 11,
            "port_mapping_template_id": 11
        },
        ...
    ]
}
```

## Details of a http mapping

Get all details of a http mapping.

```
GET /http_mappings/:id
```
Parameters:

+ `id` (required) - The ID of a http mapping

```json
{
    "http_mapping":
        {
            "id": 13,
            "application_protocol": "http",
            "url": "jacobson.co.uk",
            "appliance_id": 13,
            "port_mapping_template_id": 13
        }
}
```