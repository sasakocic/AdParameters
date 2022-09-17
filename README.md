# AdParameters

## Backend Challenge

The purpose of this challenge is to test your ability to write a clean and simple application that is
manipulating some configuration data coming from a fictional frontend
Your goal is to:
- Write a clean application that is solving the challenge
- Make sure the code is tested

Code Challenge: Customers are setting their advertising configuration in a dashboard. This
dashboard is developed in php, using complex technologies and it is storing its data in several
databases. However, every three minutes, a batch job is exporting dashboard configuration data
into an XML files. The format of the xml is very simple and it looks like the following

```xml
<Creatives>
    <Creative id="Video-1" price="6.4567" currency="EUR"/>
    <Creative id="Video-4" price="1.1234" currency="USD"/>
    <Creative id="Video-7" price="55.123" currency="SEK"/>
    <Creative id="Video-12" price="16.4567" currency="EUR"/>
    <Creative id="Video-25" price="9.4567" currency="USD"/>
</Creatives>

<Placements>
    <Placement id="plc-1" floor="1.3456" currency="EUR"/>
    <Placement id="plc-2" floor="90.234" currency="SEK"/>
    <Placement id="plc-3" floor="8.343" currency="TYR"/>
    <Placement id="plc-4" floor="20.56" currency="USD"/>
    <Placement id="plc-5" floor="27.9856" currency="EUR"/>
    <Placement id="plc-6" floor="22.5656" currency="SEK"/>
    <Placement id="plc-7" floor="0" currency="EUR"/>
    <Placement id="plc-8" floor="1.3456" currency="USD"/>
</Placements>
```

Here you see that creative has three attributes:
- the id which is unique for each creative
- the price that indicates how worth is this creative
- The currency of the price
Placements are spaces in apps where creatives are going to be shown and they have three attributes:
- the id which is unique for each placement
- the floor price that indicates what is the minimal price of a creative in order to be shown
- The currency of the price

A creative with a price higher than a floor price of placement has the right to be shown on this placement,
others cannot be shown. For example, Video-1 can be shown on plc-2 because 6.4567>=4.234.
On the other side, Video-1 cannot be shown on plc-4 because its price is too low.
The remaining part of the system is then accepting the configuration using google protobuf and the format
of the message is the following

```protobuf
package FYBER.userconfiguration;
message Creative{
  required string id = 1;
  required float price = 2; //this is in EUR
};
message CreativeSeq{
  repeated Creative creative = 1;
};
message Placement{
  required string id = 1;
  repeated Creative creative = 2;
};
message PlacementSeq{
  repeated Placement placement = 1;
};
```

Your task is to create an application called AdParameters that reads the input xml file and
creates a PlacementSeq. In order to show the output use a function that is printing the final
protobuf to stdout. You see that in the message Placement there is a sequence of creatives; use
the following rule in order to associate creatives to placement
- if price of a creative >= floor price of placement then the creative should be part of the
  sequence
- if price of a creative < floor price of placement then the creative should NOT be part of
  the sequence
  Please take care of the following points:
- Make sure that you convert prices in one unique reference currency (EUR) and store
  everything in EUR inside the protobuf object
- Use the following exchange rate:
- EUR TO TYR: 1:3.31
- EUR TO USD: 1:1.13

BONUS: Create a web server that when requested a placement with a floor price returns the
creative a creative that pays at least that floor price

## Solution

The input file.xml has multiple roots as it is not well-formed XML.
So it needs to be split with regular expression and xml parse each part into creatives and placements.
Conversion to EUR needs to be done, we are a complete table of currencies, but for the example given,
we can just add SEK to the conversion table which is done as a constant to simplify the task.
In a real application this would be like a table refreshed daily with currency rates.

The algorithm itself takes each placement and based on the floor value selects creatives which have
price bigger than the floor value.
So we will iterate through N placements and then through M creatives, which gives us o(M*N).
As we do not expect a huge number of these, I will not optimise the algorithm, but will outline how it can be done.
First, we sort the creatives by price and the placements by the floor value in reverse order.
Then we iterate through creatives and find the first that has price bigger then the biggest floor value.
Since it is sorted, we include all the following values as they have bigger price also. 
We cache the included creatives and remember from which point the creatives became bigger.
Then for the next placement which has a lower floor value we search only until this remembered point
as we automatically include all cached creatives as they are already bigger than this smaller floor value.
So, considering that we need to do sorting of creatives and placements first, for smaller values of M and N
this algorithm will not be faster, hence the unnecessary complexity is avoided.

For the given example, the conversion to EUR gives us

    [0] = {AdParameters::PlacementStruct} #<struct AdParameters::PlacementStruct id="plc-1", floor=1.3456>
    [1] = {AdParameters::PlacementStruct} #<struct AdParameters::PlacementStruct id="plc-2", floor=8.384680215243403>
    [2] = {AdParameters::PlacementStruct} #<struct AdParameters::PlacementStruct id="plc-3", floor=2.5205438066465256>
    [3] = {AdParameters::PlacementStruct} #<struct AdParameters::PlacementStruct id="plc-4", floor=18.194690265486727>
    [4] = {AdParameters::PlacementStruct} #<struct AdParameters::PlacementStruct id="plc-5", floor=27.9856>
    [5] = {AdParameters::PlacementStruct} #<struct AdParameters::PlacementStruct id="plc-6", floor=2.096829796585506>
    [6] = {AdParameters::PlacementStruct} #<struct AdParameters::PlacementStruct id="plc-7", floor=0.0>
    [7] = {AdParameters::PlacementStruct} #<struct AdParameters::PlacementStruct id="plc-8", floor=1.1907964601769911>
    
    [0] = {AdParameters::CreativeStruct} #<struct AdParameters::CreativeStruct id="Video-1", price=6.4567>
    [1] = {AdParameters::CreativeStruct} #<struct AdParameters::CreativeStruct id="Video-4", price=0.9941592920353983>
    [2] = {AdParameters::CreativeStruct} #<struct AdParameters::CreativeStruct id="Video-7", price=5.122112812297605>
    [3] = {AdParameters::CreativeStruct} #<struct AdParameters::CreativeStruct id="Video-12", price=16.4567>
    [4] = {AdParameters::CreativeStruct} #<struct AdParameters::CreativeStruct id="Video-25", price=8.368761061946904>

The result as JSON shows that for every placement, only creatives with bigger prices are selected. 

```json
{
  "placement": [
    {
      "id": "plc-1",
      "creative": [
        {
          "id": "Video-1",
          "price": 6.4567
        },
        {
          "id": "Video-7",
          "price": 5.12211275
        },
        {
          "id": "Video-12",
          "price": 16.4567
        },
        {
          "id": "Video-25",
          "price": 8.36876106
        }
      ]
    },
    {
      "id": "plc-2",
      "creative": [
        {
          "id": "Video-12",
          "price": 16.4567
        }
      ]
    },
    {
      "id": "plc-3",
      "creative": [
        {
          "id": "Video-1",
          "price": 6.4567
        },
        {
          "id": "Video-7",
          "price": 5.12211275
        },
        {
          "id": "Video-12",
          "price": 16.4567
        },
        {
          "id": "Video-25",
          "price": 8.36876106
        }
      ]
    },
    {
      "id": "plc-4"
    },
    {
      "id": "plc-5"
    },
    {
      "id": "plc-6",
      "creative": [
        {
          "id": "Video-1",
          "price": 6.4567
        },
        {
          "id": "Video-7",
          "price": 5.12211275
        },
        {
          "id": "Video-12",
          "price": 16.4567
        },
        {
          "id": "Video-25",
          "price": 8.36876106
        }
      ]
    },
    {
      "id": "plc-7",
      "creative": [
        {
          "id": "Video-1",
          "price": 6.4567
        },
        {
          "id": "Video-4",
          "price": 0.994159281
        },
        {
          "id": "Video-7",
          "price": 5.12211275
        },
        {
          "id": "Video-12",
          "price": 16.4567
        },
        {
          "id": "Video-25",
          "price": 8.36876106
        }
      ]
    },
    {
      "id": "plc-8",
      "creative": [
        {
          "id": "Video-1",
          "price": 6.4567
        },
        {
          "id": "Video-7",
          "price": 5.12211275
        },
        {
          "id": "Video-12",
          "price": 16.4567
        },
        {
          "id": "Video-25",
          "price": 8.36876106
        }
      ]
    }
  ]
}
```

