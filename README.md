# AddressBase data

Scripts to convert AddressBase™ Premium CSV files into register-shaped data.

## Generated data

The names of the fields in the generated data have been picked to be consistent with other registers, whilst remaining compatible with the
[BS7666](http://www.bsigroup.com/en-GB/about-bsi/media-centre/press-releases/2006/7/Standardize-the-referencing-and-addressing-of-geographical-objects/)
standard and have been informed by [Open Addresses UK](https://alpha.openaddressesuk.org/).

### Address

- address — The UPRN of the property or premises being addressed encoded using Douglas Crockford's [base32 encoding scheme](http://www.crockford.com/wrmg/base32.html).
- street — the Unique Street Reference Number (USRN)
- street-custodian — Geoplace LLP code for the local custodian for an address
- parent-address — a reference to the address which contains this address
- primary-address — a reference to the BS7666 primary addressable object, where found
- name — the BS7666 secondary addressable object name as a single field
- name-cy — an alternative name, in Welsh
- point — an indication of the geographic location of an address
- start-date — the date from which an entry becomes applicable
- end-date — the date from which an entry becomes no longer applicable

### Street

- street — the Unique Street Reference Number (USRN)
- street-custodian — Geoplace LLP code for the local custodian for a street
- name — the street name
- name-cy — an alternative street name, in Welsh
- place — a reference to the [place](https://github.com/openregister/place-data) discovery register, matched to the:
  - locality — the name of a locality
  - town — the name of a nearby town
  - administrative-area — the name of the administrative area
- point — an indication of the geographic location of the street
- start-date — the date from which an entry becomes applicable
- end-date — the date from which an entry becomes no longer applicable

## Source data

A local copy of AddressBase™ Premium, which includes the geographic location of addresses and historical entries is needed to build the register-shaped data.

Ordnance Survey publish the National Address Gazetteer as AddressBase™ once every six weeks, see the [timetable of releases](http://www.ordnancesurvey.co.uk/business-and-government/help-and-support/products/addressbase-epoch-dates.html) and [release notes](http://www.ordnancesurvey.co.uk/business-and-government/help-and-support/products/addressbase-release-notes.html).

### Ordering

AddressBase™ Premium is obtainable by government organisations who are members of the [Public Sector Mapping Agreement (PSMA)](https://www.ordnancesurvey.co.uk/business-and-government/public-sector/mapping-agreements/public-sector-mapping-agreement.html) from the [Ordnance Survey portal](https://www.ordnancesurvey.co.uk/sso/login.shtml). 

The data can be ordered using the session-based shopping cart system. We have not found a way to automate this process:

* visit the [Ordnance Survey portal](https://www.ordnancesurvey.co.uk/sso/login.shtml). 
* visit the [orders page](https://orders.ordnancesurvey.co.uk/orders/index.html)
* order a new copy AddressBase™ Premium 5km Download in CSV format "Full Supply"
* "order more"
* select the whole map
* add the order to your basket
* visit your basket, checkout
* your order should appear in the list of orders for your organisation
* sometime later a download page for your order will appear in the list of downloads for your organisation
* visit the download page (not a bookmarkable URL) and use your browser to save the page as `cache/download.html`

### Downloading

Use make to download the AddressBase CSV files in the `cache/AddressBase` directory:

    $ make download

### Building

Building depends upon [Go](https://golang.org/doc/install):

    $ make init
    $ make -j4

Register-shaped tab-separated value files are produced in the data directory, and a log of any issues encountered is produced in the `log` directory.

### Further documentation

* [AddressBase Premium documentation](https://www.ordnancesurvey.co.uk/business-and-government/help-and-support/products/addressbase-premium.html)
* [NLPG Data entry conventions](http://www.iahub.net/docs/1398672866952.pdf)
* [UPRN classification codes](https://www.geoplace.co.uk/documents/10181/41984/2015%20the%20UPRN%20lifecycle%20V3%20%28CMS%20ID%20-%201429701616057%29)
* [UPRN lifecycle](https://www.geoplace.co.uk/documents/10181/41984/2015%20the%20UPRN%20lifecycle%20V3%20%28CMS%20ID%20-%201429701616057%29)

# Licence

The software in this project is open source, covered by [LICENSE](LICENSE) file.

The copyright and licensing of the source data is not open and falls under terms of Ordnance Survey AddressBase™.
