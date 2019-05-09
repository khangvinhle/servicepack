# API for Service Packs module

This is a necessary extension for OpenProject existing API system as time logging function is clobbered by this module.

Part two of this document is [Service Packs Assignment API](api_Service_Packs_Assignment.md).

## Extension field to TimeEntry API

This module added `servicePackId` to TimeEntry request and response body.

### Create Time Entry

`POST` `/api/v3/time_entries`

`servicePackId` must be an Integer. `servicePackId` is **ignored** if and only if the `project` does not have Service Packs module enabled.

Request body:

```json
{
 "_links": {
    "project": {
      "href": "/api/v3/projects/7"
    },
    "activity": {
      "href": "/api/v3/time_entries/activities/14"
    },
    "workPackage": {
      "href": "/api/v3/work_packages/95"
    }
  },
  "hours": "PT1H",
  "comment": "some comment",
  "spentOn": "2017-07-28",
  "servicePackId": 1
}
```

Response body:

`201 Created`

Besides from servicePackId now has the **name** of Service Pack consumed by this entry, the response structure is unchanged from the core API.

~~~json
{
  "_type": "TimeEntry",
  "id": 213,
  "comment": "some comment",
  "spentOn": "2017-07-28",
  "hours": "PT1H",
  "createdAt": "2019-05-08T08:07:40Z",
  "updatedAt": "2019-05-08T08:07:40Z",
  "servicePackId": "SPPJ2", // <- here
  "_embedded": {
    "project": {
      "_type": "Project",
      "id": 7,
      "identifier": "r-d-project",
      "name": "Test project",
      "description": "OpenProject++ 2019",
      "createdAt": "2019-02-08T13:39:32Z",
      "updatedAt": "2019-04-18T16:07:29Z",
      "_links": {
        "self": {
          "href": "/api/v3/projects/7",
          "title": "Test project"
        },
        "createWorkPackage": {
          "href": "/api/v3/projects/7/work_packages/form",
          "method": "post"
        },
        "createWorkPackageImmediate": {
          "href": "/api/v3/projects/7/work_packages",
          "method": "post"
        },
        "categories": {
          "href": "/api/v3/projects/7/categories"
        },
        "versions": {
          "href": "/api/v3/projects/7/versions"
        },
        "types": {
          "href": "/api/v3/projects/7/types"
        }
      }
    }
    // same as OP
  }
}
~~~

`422 Unprocessable Entity`

SP constraint related to TimeEntry are now implemented as a part of `ModelContract` for TimeEntry.

When this Service Pack is not assigned to this project:

~~~json
{
    "_type": "Error",
    "errorIdentifier": "urn:openproject-org:api:v3:errors:PropertyConstraintViolation",
    "message": "This Service Pack is not assigned to this project" // <- this line
}
~~~

When the Service Pack will not have enough units:

~~~json
{
    "_type": "Error",
    "errorIdentifier": "urn:openproject-org:api:v3:errors:PropertyConstraintViolation",
    "message": "Service Pack selected does not have enough units!" // <- this line
}
~~~

`400 Bad Request`

The body request cannot be parsed as valid JSON.

~~~json
{
  "_type": "Error",
  "errorIdentifier": "urn:openproject-org:api:v3:errors:InvalidRequestBody",
  "message": "The request could not be parsed as JSON.",
  "_embedded": {
    // diagnostic info
  }
}
~~~

`403 Forbidden`

Please refer to OpenProject API.

### Show Time Entry

`GET` `api/v3/time_entries/{id}`

Request body: None

Response body:

`200 OK`

Same as `201 Created` from the section **Create Time Entry**. Besides from servicePackId now has the **name** of Service Pack consumed by this entry, the response structure is unchanged from the core API.

`404 Not Found`

See OpenProject API documentation.

### Edit Time Entry

`PATCH` `api/v3/time_entries/{id}`

Same as Create Time Entry. For more information please consult the more authortative OpenProject API documentation.
