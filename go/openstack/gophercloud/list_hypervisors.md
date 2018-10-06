# SHOW HYPERVISOR INFO

## BACKGROUND

After deploying stacklight components on `mon` nodes (Mirantis), when executing `docker logs ${MONITOR_CONTAINER}`, it is reporting hypervisor has unexpected JSON input which makes hypervisor related information unavailable. The same problem occurs on staging environment as well. In order to look for the root cause, I prepare download `gophercloud` and test code snippet manually.

## CODE SNIPPET

A minimal code snippet for replicating problem, it is claiming `unexpected end of JSON input` when you executing it. I am still looking for the root cause.

```go
package main

import (
    "crypto/tls"
    "fmt"
    "github.com/gophercloud/gophercloud"
    "github.com/gophercloud/gophercloud/openstack"
    "github.com/gophercloud/gophercloud/openstack/compute/v2/extensions/hypervisors"
    "github.com/gophercloud/gophercloud/openstack/compute/v2/servers"
    "github.com/gophercloud/gophercloud/pagination"
    "net/http"
)

func disableSSLVerification() {
    http.DefaultTransport.(*http.Transport).TLSClientConfig = &tls.Config{InsecureSkipVerify: true}
}

func listHypervisors(provider *gophercloud.ProviderClient) (bool, error) {

    client, err := openstack.NewComputeV2(provider, gophercloud.EndpointOpts{
        Region: "RegionOne",
    })

    if err != nil {
        panic(err)
    }

    pages, err := hypervisors.List(client).AllPages()

    if err != nil {
        panic(err)
    }

    // print body
    fmt.Println(pages.GetBody())

    allHypervisors, err := hypervisors.ExtractHypervisors(pages)

    if err != nil {
        panic(err)
    }

    for _, s := range allHypervisors {
        fmt.Println(s)
    }

    return true, nil
}

func extracInfo(p pagination.Page) {
    var h struct {
        Hypervisors []hypervisors.Hypervisor `json:"hypervisors"`
    }

    body := (p.(hypervisors.HypervisorPage)).Body

    json_body, _ := json.Marshal(body)

    ioutil.WriteFile("./jsons/output2.json", json_body, 0644)

    // err := (p.(hypervisors.HypervisorPage)).ExtractInto(&h)

    err := json.Unmarshal(json_body, &h)

    if err != nil {
        fmt.Println("extrac info")
        panic(err)
    }

    fmt.Println(h)
}

func unmarshalHypervisor() {

    data, err := ioutil.ReadFile("./jsons/output2.json")

    if err != nil {
        panic(err)
    }

    var h struct {
        Hypervisors []hypervisors.Hypervisor `json:"hypervisors"`
    }

    err = json.Unmarshal(data, &h)

    if err != nil {
        panic(err)
    }

    fmt.Println(h)

}

func main() {

    // disable ssl verification
    disableSSLVerification()

    opts := gophercloud.AuthOptions{
        IdentityEndpoint: "https://10.110.25.117:5000/v2.0",
        Username:         "sjt",
        Password:         "sjt",
        TenantName:       "sjt",
    }
    provider, err := openstack.AuthenticatedClient(opts)

    if err != nil {
        fmt.Println(err)
        return
    }

    listHypervisors(provider)
}

```

## REASON

The problem finally turns to be that ironic driver does not return a valid `CPUInfo` field as a normal nova driver does which failed the json deserialization process. In order to avoid this error message, we may either modify code ourselves or simply adding up some fake cpu information.