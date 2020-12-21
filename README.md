# F5 Networks BIG-IP™ Virtual Edition Instance Creation using Catalog image

This directory contains the Terraform module to create BIG-IP™ VPC Gen2 instances using catalog input from the user.

Use this template to create BIG-IP™ Virtual Edition instances using catalog image from your IBM Cloud account in IBM Cloud [VPC Gen2](https://cloud.ibm.com/vpc-ext/overview) by using Terraform or IBM Cloud Schematics.  Schematics uses Terraform as the infrastructure-as-code engine.  With this template, you can create and manage infrastructure as a single unit as follows. For more information about how to use this template, see the IBM Cloud [Schematics documentation](https://cloud.ibm.com/docs/schematics).

This template uses the new IBM VPC Gen2 custom route feature to create VPC subnets container IPs which can be used as routable virtual service addresses and routable SNAT pool addresses.

This template requires that the F5 TMOS™ qcow2 images be patched including the IBM VPC Gen2 cloudinit config and the full complement of tmos-cloudinit modules. The template also requires the f5-declarative-onboarding AT extension version 1.16.0 or greater be included in the patched image.

This Schematics template allows the user to specify a HTTP(S) URL to download the cloud-init user-data. The user-data can container F5 AT toolchain declarations to provision your BIG-IP™ Virtual Edition instance. Documentation for this extension can be found at:

[F5 Cloud Documentation for the F5 Declarative Onboarding Extension](https://clouddocs.f5.com/products/extensions/f5-declarative-onboarding/latest/)

[F5 Cloud Documentation for the F5 Application Services 3 Extension](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/)

[F5 Cloud Documentation for the F5 Telemetry Services Extension](https://clouddocs.f5.com/products/extensions/f5-telemetry-streaming/latest/)

## IBM Cloud IaaS Support

You're provided free technical support through the IBM Cloud™ community and Stack Overflow, which you can access from the Support Center. The level of support that you select determines the severity that you can assign to support cases and your level of access to the tools available in the Support Center. Choose a Basic, Advanced, or Premium support plan to customize your IBM Cloud™ support experience for your business needs.

Learn more: https://www.ibm.com/cloud/support

## Prerequisites

- Have access to [Gen 2 VPC](https://cloud.ibm.com/vpc-ext/).
- The given VPC must have at least one subnet with one IP address unassigned (up to 5 are supported)
- The BIG-IP™ image name can reference the name of a custom image in your region or the public TMOS images available on IBM cloud.

**User variable:** ```region```

**Values:**

- ```us-south```
- ```us-east```
- ```eu-gb```
- ```eu-de```
- ```jp-tok```
- ```au-syd```

The IBM VPC Gen2 region to create your BIG-IP™ Virtual Edition instance.

**User variable:** ```resource_group```

The resource group used to create your BIG-IP™ Virtual Edition instance and optionally the subnets for virtual service IPs and SNAT pool IPs.

**User variable:** ```instance_name```

The IBM VPC Gen2 instance name for your BIG-IP™ Virtual Edition instance.

**User variable:** ```tmos_image_name```

Public BIG-IP™ images available on IBM Cloud are:

**Values:**

- ```bigip-14-1-2-6-0-0-2-all-1slot```
- ```bigip-14-1-2-6-0-0-2-ltm-1slot```
- ```bigip-15-1-0-4-0-0-6-all-1slot```
- ```bigip-15-1-0-4-0-0-6-ltm-1slot```

You can specify one of those or you can use a custom VPC image name.

**User variable:** ```instance_profile```

The IBM VPC Gen2 instance profile name to use for your BIG-IP™ Virtual Edition instance.

## Device authentication

The user should create an SSH key in the IBM cloud region. The SSH key name should be included as a user variable.

**User Variable:** ```ssh_key_name```

Once the image completes onboarding, SSH access to the ```root``` user is available on the defined management Floating IP.

The user should also provide an ```admin``` user password.

**User Variable:** ```tmos_admin_password```

If no ```tmos_admin_password``` is provided, a randomized lengthy password will be set. The user can then access the device via SSH authorized key and set the ```admin``` password by using ```passwd admin```.

## Device Network Connectivity

Currently, IBM terraform resources do not provide the ability to obtain VPC subnets by their name. The user will have to know the subnet UUID as input variables.

At least one VPC subnet must be defined:

**User Variable:** ```management_subnet_id```

If only the ```management_subnet_id``` id is defined, the BIG-IP™ will be created as a 1NIC instance. The management UI and APIs can then be reached on port 8443 instead of the standard 443.

**User Variables:** ```data_cluster_subnet_id```

The subnet ID for the BIG-IP™  1.1 data networking interface. This will be used only for configuration synchronization between devices.

**User Variables:** ```data_internal_subnet_id```

The subnet ID for the BIG-IP™  1.2 data networking interface. This will be used to route request to internal resources.

**User Variables:** ```internal_snat_pool_count```

This is the number of SNAP pool addresses you would like allocated by this template.

**Values:**

```1```  - do not allocate a subnet for SNAP pools, only the SelfIP will be available.
```8```  - allocate a /29 IPv4 subnet for use as SNAT pool addresses, updating the supplied routing tables with the SelfIP as the next-hop address.
```16``` - allocate a /28 IPv4 subnet for use as SNAT pool addresses, updating the supplied routing tables with the SelfIP as the next-hop address.

**User Variables:** ```data_external_subnet_id```

The subnet ID for the BIG-IP™  1.3 data networking interface. This will be used to route request from clients to virtual services.

**User Variables:** ```external_virtual_address_count```

This is the number of virtual service addresses you would like allocated by this template.

**Values:**

```1```  - do not allocate a subnet for virtual services, only the SelfIP will be available.
```8```  - allocate a /29 IPv4 subnet for use as virtual service addresses, updating the supplied routing tables with the SelfIP as the next-hop address.
```16``` - allocate a /28 IPv4 subnet for use as virutal service addresses, updating the supplied routing tables with the SelfIP as the next-hop address.

**User Variables:** ```routing_table_ids```

The VPC routing table ID to update with the SelfIP next-hop address for both SNAT pool and virtual services subnets.

**Values:**

This is a list of routing table ID string.

```["r006-dfcc0260-04b4-4eba-89b6-def1a3e53289","r006-b93f6e8a-72fb-4f3f-966c-2b14a5dcfa61","r006-fd89a889-9a3c-4ca5-8d2f-2863e4b62e39"]```

## CI Integration via Webhooks

When onboarding is complete, including optional licensing and network interface provisioning, the BIG-IP™ can issue an HTTP(s) POST request to an URL specified by the user.

**User Variables:**

```phone_home_url```

The POST body will be JSON encoded and supply basic instance information:

```json
{
    "status": "SUCCESS",
    "product": "BIG-IP",
    "version": "14.1.2.6-0.0.2.0",
    "hostname": "f5-test-ve-01.local",
    "id": "27096838-e85f-11ea-ac1c-feff0b2c5217",
    "management": "10.243.0.7/24",
    "installed_extensions": ["f5-service-discovery", "f5-declarative-onboarding", "f5-appsvcs", "f5-telemetry", "f5-appsvcs-templates"],
    "do_enabled": true,
    "as3_enabled": false,
    "ts_enabled": false,
    "metadata": {
        "template_source": "/f5devcentral/ibmcloud_schematics_bigip_multinic/tree/master",
        "template_version": 20200825,
        "zone": "eu-de-1",
        "vpc": "r010-e27c516a-22ff-41f5-96b8-e8ea833fd39f",
        "app_id": "undefined"
    }
}
```

The user can optionally define an ```app_id``` variable to tie this instnace for reference.

**User Variables:**

```app_id```

Once onboarding is complete, the user can than access the TMOS™ Web UI, use iControl™ REST API endpoints, or utilize the [F5 BIG-IP™ Extensibility Extensions](https://clouddocs.f5.com/) installed.

**User Variable:** ```user_data_template_url```

The URL to request the user_data template to include.

**User Variable:** ```user_data_base_auth_username```

The username to include when building a BASIC AUTH HTTP header for the user_data HTTP(S) request.

**User Variable:** ```user_data_base_auth_password```

The password to include when building a BASIC AUTH HTTP header for the user_data HTTP(S) request.

**User Variable:** ```user_data_github_personal_access_token```

The github personal access token value to include in an HTTP header for the user_data HTTP(S) request.

**Note:**

You user_data must include the following terraform tempalte module replacement variable strings.

```${tmos_admin_password}``` - replaced with the specificed ```tmos_admin_password``` variable
```${snat_pool_addresses}``` - replaced with a YAML list of the addresses allocated for SNAT pool addresses
```${phone_home_url}``` - replaed with the specified ```phone_home_url``` variable
```${zone}``` - replaced with the IBM zone
```${vpc}``` - replaced wiht the IBM VPC id
```${management_subnet_cidr}``` - replaced with the IPv4 management interface CIDR
```${cluster_subnet_cidr}``` - replaced with the IPv4 cluster interface CIDR
```${internal_subnet_cidr}``` - replaced with the IPv4 internal interface CIDR
```${external_subnet_cidr}``` - replaced with the IPv4 external interface CIDR
```${virtual_service_addresses}``` - replaced with a YAML list of the addresses allocated for virtual service addresses
```${appid}``` - replaced with the specified ```appid``` variable

If your user_data does not require the replacements, simply use YAML comments (```# comment```) to include these variables in your user_data.

```
# zone: ${zone}
# vpc: ${vpc}
# management_subnet_cidr: ${management_subnet_cidr}
# cluster_subnet_cidr: ${cluster_subnet_cidr}
# internal_subnet_cidr: ${cluster_subnet_cidr}
# snat_pool_addresses: ${snat_pool_addresses}
# external_subnet_cidr: ${external_subnet_cidr}
# virtual_service_addresses: ${virtual_service_addresses}
# appid: ${appid}
...
```

## Costs

When you apply the template, the infrastructure resources that you create incur charges as follows. To clean up the resources, you can [delete your Schematics workspace or your instance](https://cloud.ibm.com/docs/schematics?topic=schematics-manage-lifecycle#destroy-resources). Removing the workspace or the instance cannot be undone. Make sure that you back up any data that you must keep before you start the deletion process.

*_VPC_: VPC charges are incurred for the infrastructure resources within the VPC, as well as network traffic for internet data transfer. For more information, see [Pricing for VPC](https://cloud.ibm.com/docs/vpc-on-classic?topic=vpc-on-classic-pricing-for-vpc).

## Dependencies

Before you can apply the template in IBM Cloud, complete the following steps.

1.  Ensure that you have the following permissions in IBM Cloud Identity and Access Management:
    * `Manager` service access role for IBM Cloud Schematics
    * `Operator` platform role for VPC Infrastructure
2.  Ensure the following resources exist in your VPC Gen 2 environment
    - VPC
    - SSH Key
    - VPC with multiple subnets

## Configuring your deployment values

Create a schematics workspace and provide the github repository url (https://github.com/f5devcentral/ibmcloud_schematics_bigip_multinic/tree/master) under settings to pull the latest code, so that you can set up your deployment variables from the `Create` page. Once the template is applied, IBM Cloud Schematics provisions the resources based on the values that were specified for the deployment variables.

### Required values
Fill in the following values, based on the steps that you completed before you began.

| Key | Definition | Value Example |
| --- | ---------- | ------------- |
| `region` | The VPC region that you want your BIG-IP™ to be provisioned. | us-south |
| `instance_name` | The name of the VNF instance to be provisioned. | f5-ve-01 |
| `tmos_image_name` | The name of the VNF image  | bigip-14-1-2-6-0-0-2-all-1slot |
| `instance_profile` | The profile of compute CPU and memory resources to be used when provisioning the BIG-IP™ instance. To list available profiles, run `ibmcloud is instance-profiles`. | cx2-4x8 |
| `ssh_key_name` | The name of your public SSH key to be used. Follow [Public SSH Key Doc](https://cloud.ibm.com/docs/vpc-on-classic-vsi?topic=vpc-on-classic-vsi-ssh-keys) for creating and managing ssh key. | linux-ssh-key |
| `management_subnet_id` | The ID of the management subnet id. Click on the subnet details in the VPC Subnet Listing to determine this value | xxxx-xxxxxx-xxxx-xxxxx-xxxx-xxxxx |
| `data_cluster_subnet_id` | The ID of the cluster subnet id. Click on the subnet details in the VPC Subnet Listing to determine this value | xxxx-xxxxxx-xxxx-xxxxx-xxxx-xxxxx |
| `data_internal_subnet_id` | The ID of the internal subnet id. Click on the subnet details in the VPC Subnet Listing to determine this value | xxxx-xxxxxx-xxxx-xxxxx-xxxx-xxxxx |
| `data_external_subnet_id` | The ID of the external subnet id. Click on the subnet details in the VPC Subnet Listing to determine this value | xxxx-xxxxxx-xxxx-xxxxx-xxxx-xxxxx |
| `user_data_tempalte_url` | The HTTP(S) URL for the user_data YAML to include in the instance createion | https://example.com/user_data_01.yaml |

### Optional values
Fill in the following values, based on the steps that you completed before you began.

| Key | Definition | Value Example |
| --- | ---------- | ------------- |
| `tmos_admin_password` | The password to set for the BIG-IP™ admin user. | valid TMOS password |
| `internal_snat_pool_count` | The ID of the first data subnet where the instance will be deployed. Click on the subnet details in the VPC Subnet Listing to determine this value | 0717-xxxxxx-xxxx-xxxxx-8fae-xxxxx |
| `external_virtual_address_count` | The ID of the first data subnet where the instance will be deployed. Click on the subnet details in the VPC Subnet Listing to determine this value | 0717-xxxxxx-xxxx-xxxxx-8fae-xxxxx |
| `routing_table_ids` | The ID of the first data subnet where the instance will be deployed. Click on the subnet details in the VPC Subnet Listing to determine this value | 0717-xxxxxx-xxxx-xxxxx-8fae-xxxxx |
| `phone_home_url` | The URL for post onboarding web hook  | https://webhook.site/#!/8c71ed42-da62-48ea-a2a5-265caf420a3b |
| `app_id` | Application ID used for CI integration | a044b708-66c4-4f50-a5c8-2b54eff5f9b5 |
| `user_data_basic_auth_username` | The username to include in a BASIC AUTH header for the user_data request | admin |
| `user_data_basic_auth_password` | The password to include in a BASIC AUTH header for the user_data request | admin |
| `user_data_github_personal_access_token` | The github PAT to include in the Authorization header for the user_data request | admin |

## Notes

If there is any failure during VPC instance creation, the created resources must be destroyed before attempting to instantiate again. To destroy resources go to `Schematics -> Workspaces -> [Your Workspace] -> Actions -> Delete` to delete all associated resources.

## Post F5 BIG-IP™ Virtual Edition Onboarding

1. From the VPC list, confirm the F5 BIG-IP™ Virtual Edition is powered ON with green button
2. From the CLI, run `ssh root@<management IP>`.
3. Enter 'yes' for continue connecting using ssh your key. This is the ssh key value, you specified in ssh_key variable.
4. Use the ```tmsh``` shell.

Alternatively, the F5 Declarative Onboading, F5 Application Service 3, and F5 Telemetry Streaming service endpoints are available at:

```text
https://<management IP>/mgmt/shared/declarative-onboarding
https://<management IP>/mgmt/shared/appsvcs
https://<management IP>/mgmt/shared/telemetry
```

These endpoints provide declarative orchestration of multiple NFV functions including L4-L7 ADC funcationality, network firewalls, web application firewalls, and DNS services.

## Troubleshooting Known Error States

The following errors were discovered in exhaustive testing of this Schematics template.

### User providing invalid image name

F5 BIG-IP™ Virtual Edition images names can be specified to match either custom images within an account's VPCs or can use the images available as part of the IBM public cloud image catalog. The image ids for the public cloud images are enumerated in a map embedded within the template itself. If the image name provided can not be mapped to a VPC custom image name nor a public cloud image name embedded in the template, the following error will occuring in your plan or apply phase:

```text
XXXX/XX/XX XX:XX:XX Terraform plan | Error: Invalid index
XXXX/XX/XX XX:XX:XX Terraform plan |
XXXX/XX/XX XX:XX:XX Terraform plan |   on compute.tf line 69, in locals:
XXXX/XX/XX XX:XX:XX Terraform plan |   69:   image_id = data.ibm_is_image.tmos_custom_image.id == null ? lookup(local.public_image_map[var.tmos_image_name], var.region) : data.ibm_is_image.tmos_custom_image.id
XXXX/XX/XX XX:XX:XX Terraform plan |     |----------------
XXXX/XX/XX XX:XX:XX Terraform plan |     | local.public_image_map is object with 4 attributes
XXXX/XX/XX XX:XX:XX Terraform plan |     | var.tmos_image_name is "bigip-16-0-0-0-0-12-all-1slot-us-south"
XXXX/XX/XX XX:XX:XX Terraform plan |
XXXX/XX/XX XX:XX:XX Terraform plan | The given key does not identify an element in this collection value.
XXXX/XX/XX XX:XX:XX Terraform plan |
XXXX/XX/XX XX:XX:XX Terraform PLAN error: Terraform PLAN errorexit status 1
XXXX/XX/XX XX:XX:XX Could not execute action
```

To remedy this error, provide a valid image name and re-plan or re-apply.

### Failures within the Schematics service

If the Schematics system received a user_data YAML which is lengthy, it appears to cause the instance creation to hang. You will see the following messages until the authentication token now longer is valid.


```text
XXXX/XX/XX XX:XX:XX Terraform apply | ibm_is_instance.f5_ve_instance: Creating...
XXXX/XX/XX XX:XX:XX Terraform apply | ibm_is_instance.f5_ve_instance: Still creating... [19m40s elapsed]
XXXX/XX/XX XX:XX:XX Terraform apply | 
XXXX/XX/XX XX:XX:XX Terraform apply | Error: Error Getting Instance: provided token is invalid or expired
XXXX/XX/XX XX:XX:XX Terraform apply | {
XXXX/XX/XX XX:XX:XX Terraform apply |     "StatusCode": 401,
XXXX/XX/XX XX:XX:XX Terraform apply |     "Headers": {
XXXX/XX/XX XX:XX:XX Terraform apply |         "Cache-Control": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "max-age=0, no-cache, no-store, must-revalidate"
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "Cf-Cache-Status": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "DYNAMIC"
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "Cf-Ray": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "6052d4195ab315b3-EWR"
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "Cf-Request-Id": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "0727a2e3d8000015b3740b6000000001"
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "Connection": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "keep-alive"
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "Content-Length": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "135"
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "Content-Type": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "application/json; charset=utf-8"
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "Date": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "Mon, 21 Dec 2020 XX:XX:XX GMT"
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "Expect-Ct": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "max-age=604800, report-uri=\"https://report-uri.cloudflare.com/cdn-cgi/beacon/expect-ct\""
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "Expires": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "-1"
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "Pragma": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "no-cache"
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "Server": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "cloudflare"
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "Set-Cookie": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "__cfduid=d8a7f70401dc4fbeb6ed290fdfcb644a71608566557; expires=Wed, 20-Jan-21 XX:XX:XX GMT; path=/; domain=.iaas.cloud.ibm.com; HttpOnly; SameSite=Lax; Secure"
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "Strict-Transport-Security": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "max-age=31536000; includeSubDomains"
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "Vary": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "Accept-Encoding"
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "X-Content-Type-Options": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "nosniff"
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "X-Request-Id": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "4a38d48d-81b1-4b60-a0ae-cc8a5f18ab9c"
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "X-Trace-Id": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "7b23cba461406375"
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "X-Xss-Protection": [
XXXX/XX/XX XX:XX:XX Terraform apply |             "1; mode=block"
XXXX/XX/XX XX:XX:XX Terraform apply |         ]
XXXX/XX/XX XX:XX:XX Terraform apply |     },
XXXX/XX/XX XX:XX:XX Terraform apply |     "Result": {
XXXX/XX/XX XX:XX:XX Terraform apply |         "errors": [
XXXX/XX/XX XX:XX:XX Terraform apply |             {
XXXX/XX/XX XX:XX:XX Terraform apply |                 "code": "not_authorized",
XXXX/XX/XX XX:XX:XX Terraform apply |                 "message": "provided token is invalid or expired"
XXXX/XX/XX XX:XX:XX Terraform apply |             }
XXXX/XX/XX XX:XX:XX Terraform apply |         ],
XXXX/XX/XX XX:XX:XX Terraform apply |         "trace": "4a38d48d-81b1-4b60-a0ae-cc8a5f18ab9c"
XXXX/XX/XX XX:XX:XX Terraform apply |     },
XXXX/XX/XX XX:XX:XX Terraform apply |     "RawResult": null
XXXX/XX/XX XX:XX:XX Terraform apply | }
XXXX/XX/XX XX:XX:XX Terraform apply | 
XXXX/XX/XX XX:XX:XX Terraform apply | 
XXXX/XX/XX XX:XX:XX Terraform apply |   on compute.tf line 115, in resource "ibm_is_instance" "f5_ve_instance":
XXXX/XX/XX XX:XX:XX Terraform apply |  115: resource "ibm_is_instance" "f5_ve_instance" {
```

If you experience this, please open a support case with IBM cloud so they can examine the Schematics error.

### Failure in the IBM Terraform Providers running in the Schematics service

This template uses only community and IBM authored Terraform resource providers. Both of which are supported under Schematics.

*There are no F5 Terraform resource providers used by this template, thus nothing to report to F5 when Terraform resources fail. All Terraform resources used in this template are supported by IBM.*

When Schematics experiences an error with the community or IBM authorized Terraform resource providers, the cause of the issue will be in the log entries of the failing workspace phase logs. As an example, the following log entry will be present when the `ibm_is_instance` provider experiences issues with the IBM VPC Gen2 instance APIs:

```text
XXXX/XX/XX XX:XX:XX Terraform apply | ibm_is_instance.f5_ve_instance: Creating...
XXXX/XX/XX XX:XX:XX Terraform apply |
XXXX/XX/XX XX:XX:XX Terraform apply | Error: internal server error
XXXX/XX/XX XX:XX:XX Terraform apply |
XXXX/XX/XX XX:XX:XX Terraform apply |   on compute.tf line 109, in resource "ibm_is_instance" "f5_ve_instance":
XXXX/XX/XX XX:XX:XX Terraform apply |  109: resource "ibm_is_instance"
```

If you experience this, please open a support case with IBM cloud so they can examine the Schematic supported Terraform resource providers.

### Failure in the F5 Declarative Onboarding declaration

If your F5 BIG-IP™ Virtual Edition instance fails to reach the operational state, please login to the instance using the supplied IBM VPC Gen2 SSH key at:

`ssh root@<management IP>`

The reason for the failures can be found in the `/var/log/restnoded/restnoded.log` file. Search for the term '`Rolling back configuration`' and the cause for the declaration failure should immediately proceed the presence of the searched entry for '`Rolling back configuration`'.

As an example, if the virtualization infrastructure performance is insufficent to appropriately run needed services within F5 TMOS™ you will see log entries like this:

```text
[f5-declarative-onboarding: restWorker.js] tryUntil: got error {"code":503,"message":"tryUntil: max tries reached: Unable to process request /tm/sys/available. Service is unavailable.","name":"Error"}
```

immediately proceeding the line which reads:

```text
[f5-declarative-onboarding: restWorker.js] Rolling back configuration
```

If you see that the system services did not become available, delete the workspace and start another. This type of error happens less then 1% of the time in IBM VPC Gen2 cloud, but has been noted. Creating another workspace from this template is the solution.

As a second example, if there were issues licensing your F5 BIG-IP™ Virtual Edition instance because of Utility pool grant exhaustion or communications error with the BIG-IQ you would see messages like this:

```text
[f5-declarative-onboarding: restWorker.js] Error onboarding: Error waiting for license assignment
```

immediately proceeding the line which reads:

```text
[f5-declarative-onboarding: restWorker.js] Rolling back configuration
```

In this case too, keeping with the spirit of infrastructure as code, the solution would be to correct any issue with the license pool or networking, delete the workspace, and create another from this template.
