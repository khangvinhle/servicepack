# API for Service Packs module

This is a necessary extension for OpenProject existing API system as time logging function is clobbered by this module.

First part of this document is [Extension to TimeEntry API](api_extension_TimeEntry.md).

## Service Packs Assignment API

### List of Service Packs assigned to a project

`GET` `/api/v3/projects/{id}/assignments`

Request body: None

`GET localhost:3000/api/v3/projects/7/assignments`

Response:

`200 OK`

The response has 2 important fields: `count` (of elements) and `elements`. `elements` can be empty (no Service Packs are assigned to this project).

Each element is composed of these fields:

+ `servicePackId`
+ `servicePackName`
+ `assignDate`	 Date when the SP is assigned
+ `unassignDate`	 Date when this assignment expire
+ `remainedUnits` The number of units left
+ `project` 
	* `title` The name of the project
	* `href`  Link to get more information and submit to [TimeEntry API](api_extension_TimeEntry.md)

Example:

~~~json
{
  "_type": "Collection",
  "total": 2,
  "count": 2,
  "_embedded": {
    "elements": [
      {
        "_type": "Assignment",
        "servicePackId": 1,
        "servicePackName": "SPPJ",
        "assignDate": "2019-04-12",
        "unassignDate": "2019-06-07",
        "remainedUnits": 1668,
        "_links": {
          "project": {
            "href": "/api/v3/projects/7",
            "title": "Test project"
          }
        }
      },
      {
        "_type": "Assignment",
        "servicePackId": 5,
        "servicePackName": "SPPJ2",
        "assignDate": "2019-03-21",
        "unassignDate": "2019-06-07",
        "remainedUnits": 13183,
        "_links": {
          "project": {
            "href": "/api/v3/projects/7",
            "title": "Test project"
          }
        }
      }
    ]
  },
  "_links": {
    "self": {
      "href": ""
    }
  }
}
~~~

`304 Not Modified`

Clients are advised to make use of `If-None-Match` HTTP header in an user session for promptly checking of assignments change by filling it with the `ETag` header from the corresponding server response.

`404 Not Found`

The project does not exist or client does not have necessary permission to either:

 + Create or update time entry
 + See, or assign/unassign Service Packs from the specified project.

Response body:

~~~json
{
  "_type": "Error",
  "errorIdentifier": "urn:openproject-org:api:v3:errors:NotFound",
  "message": "The requested resource could not be found."
}
~~~

`422 Unprocessable Entity`

Client has necessary permission(s) mentioned, however Service Packs module is disabled for this project.

Response body:

~~~json
{
  "_type": "Error",
  "errorIdentifier": null,
  "message": "Service Packs module is disabled for this project" /* <-- this line */
}
~~~

<center><b>End of document</b></center>