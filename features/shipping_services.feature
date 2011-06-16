@wip
Feature:
  As a store
  I can get rates from carriers
  Through a local lookup table

  #  Background:
  #    Given UPS shipping rates are loaded
  #      And Fedex shipping rates are loaded
  #      And USPS shipping rates are loaded

  Scenario Outline: Count of cached data
    Then I have <count> of "<model>"

    Examples:
        | model                   | count  |
        | Shipury::Carrier        | 3      |
        | Shipury::USPS::Service  | 12     |
        | Shipury::Fedex::Service | 6      |
        | Shipury::UPS::Service   | 7      |
        | Shipury::USPS::Rate     | 1774   |
        | Shipury::Fedex::Rate    | 12300  |
        | Shipury::UPS::Rate      | 9840   |
        | Shipury::USPS::Zone     | 139137 |
        | Shipury::Fedex::Zone    | 243738 |
        | Shipury::UPS::Zone      | 633228 |


  Scenario Outline: From Seattle, WA to Lynnwood, WA
    Given I am shopping for a quote for the following shipping options:
        | country        | US      |
        | zip            | 98036   |
        | sender_zip     | 98125   |
        | sender_city    | Seattle |
        | sender_state   | WA      |
        | sender_country | US      |
        | weight         | 0.5     |
        | line_items     | 1       |
     When I shop for a rate from carrier "<carrier>" service "<service>"
     Then the quoted price should be "<price>"

    Examples:
      | carrier | service                            | price |
      | USPS    | Priority Mail Retail               | 5.10  |
      | USPS    | Priority Mail Flat Rate Envelope   | 4.95  |
      | USPS    | Priority Mail Small Flat Rate Box  | 5.20  |
      | USPS    | Priority Mail Medium Flat Rate Box | 10.95 |
      | USPS    | Priority Mail Large Flat Rate Box  | 14.95 |
      | USPS    | Priority Mail APO Flat Rate Box    | 12.95 |
      | USPS    | Express Mail Retail                | 15.25 |
      | USPS    | Express Mail Flat Rate Envelope    | 18.30 |
      | USPS    | First-Class Mail Flat              | 2.28  |
      | USPS    | First-Class Mail Letter            |       |
      | USPS    | First-Class Mail Parcel            | 2.56  |
      | USPS    | Parcel Post                        | 5.10  |
      | Fedex   | 2-Day                              | 11.35 |
      | Fedex   | Express Saver                      | 10.50 |
      | Fedex   | Ground                             | 5.17  |
      | Fedex   | Overnight                          | 46.30 |
      | Fedex   | Priority Overnight                 | 21.30 |
      | Fedex   | Standard Overnight                 | 17.75 |
      | UPS     | Ground                             | 5.66  |
      | UPS     | Three-Day Select                   | 9.69  |
      | UPS     | Second Day Air                     | 13.17 |
      | UPS     | Second Day Air A.M.                | 15.30 |
      | UPS     | Next Day Air Saver                 | 20.59 |
      | UPS     | Next Day Air                       | 24.71 |
      | UPS     | Next Day Air Early A.M.            | 53.71 |

  Scenario Outline: From California to Missouri
    Given I am shopping for a quote for the following shipping options:
        | country        | US       |
        | zip            | 64068    |
        | sender_zip     | 95112    |
        | sender_city    | San Jose |
        | sender_state   | CA       |
        | sender_country | US       |
        | weight         | 4.07     |
        | line_items     | 113      |
     When I shop for a rate from carrier "<carrier>" service "<service>"
     Then the quoted price should be "<price>"

    Examples:
      | carrier | service                            | price  |
      | USPS    | Priority Mail Retail               | 16.50  |
      | USPS    | Priority Mail Flat Rate Envelope   | 4.95   |
      | USPS    | Priority Mail Small Flat Rate Box  | 5.20   |
      | USPS    | Priority Mail Medium Flat Rate Box | 10.95  |
      | USPS    | Priority Mail Large Flat Rate Box  | 14.95  |
      | USPS    | Priority Mail APO Flat Rate Box    | 12.95  |
      | USPS    | Express Mail Retail                | 47.30  |
      | USPS    | Express Mail Flat Rate Envelope    | 18.30  |
      | USPS    | First-Class Mail Flat              |        |
      | USPS    | First-Class Mail Letter            |        |
      | USPS    | First-Class Mail Parcel            |        |
      | USPS    | Parcel Post                        | 11.39  |
      | Fedex   | Ground                             | 8.20   |
      | Fedex   | 2-Day                              | 30.50  |
      | Fedex   | Express Saver                      | 20.45  |
      | Fedex   | Overnight                          | 92.20  |
      | Fedex   | Priority Overnight                 | 67.20  |
      | Fedex   | Standard Overnight                 | 58.90  |
      | UPS     | Ground                             | 8.98   |
      | UPS     | Three-Day Select                   | 23.72  |
      | UPS     | Second Day Air                     | 35.38  |
      | UPS     | Second Day Air A.M.                | 41.12  |
      | UPS     | Next Day Air Saver                 | 68.32  |
      | UPS     | Next Day Air                       | 77.95  |
      | UPS     | Next Day Air Early A.M.            | 106.95 |

  Scenario Outline: From Hawaii to California
    Given I am shopping for a quote for the following shipping options:
        | country        | US       |
        | zip            | 90045    |
        | sender_zip     | 96817    |
        | sender_city    | Honolulu |
        | sender_state   | HI       |
        | sender_country | US       |
        | weight         | 1.333    |
        | line_items     | 36       |
     When I shop for a rate from carrier "<carrier>" service "<service>"
     Then the quoted price should be "<price>"

    Examples:
      | carrier | service                            | price |
      | USPS    | Priority Mail Retail               | 10.20 |
      | USPS    | Priority Mail Flat Rate Envelope   | 4.95  |
      | USPS    | Priority Mail Small Flat Rate Box  | 5.20  |
      | USPS    | Priority Mail Medium Flat Rate Box | 10.95 |
      | USPS    | Priority Mail Large Flat Rate Box  | 14.95 |
      | USPS    | Priority Mail APO Flat Rate Box    | 12.95 |
      | USPS    | Express Mail Retail                | 34.70 |
      | USPS    | Express Mail Flat Rate Envelope    | 18.30 |
      | USPS    | First-Class Mail Flat              |       |
      | USPS    | First-Class Mail Letter            |       |
      | USPS    | First-Class Mail Parcel            |       |
      | USPS    | Parcel Post                        | 8.67  |
      | Fedex   | Ground                             | 8.09  |
      | Fedex   | 2-Day                              | 17.50 |
      | Fedex   | Express Saver                      |       |
      | Fedex   | Overnight                          | 64.80 |
      | Fedex   | Priority Overnight                 | 39.80 |
      | Fedex   | Standard Overnight                 | 29.60 |
      | UPS     | Ground                             | 8.35  |
      | UPS     | Three-Day Select                   |       |
      | UPS     | Second Day Air                     | 18.68 |
      | UPS     | Second Day Air A.M.                | 23.90 |
      | UPS     | Next Day Air Saver                 | 33.76 |
      | UPS     | Next Day Air                       | 47.79 |
      | UPS     | Next Day Air Early A.M.            | 83.75 |
