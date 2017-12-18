-- Inofficial IOTA Extension for MoneyMoney
-- Fetches IOTA quantity for addresses via IOTASear.ch
-- Fetches IOTA price in EUR via coinmarketcap API
-- Returns cryptoassets as securities
--
-- Username: IOTA Adresses comma seperated
-- Password: [Whatever]

-- MIT License

-- Copyright (c) 2017 PSperber

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


WebBanking {
    version = 0.2,
    description = "Include your IOTAs as cryptoportfolio in MoneyMoney by providing IOTA addresses as usernme (comma seperated) and a random Password",
    services = { "IOTA" }
}

local iotaAddress
local connection = Connection()
local currency = "EUR" -- fixme: make dynamik if MM enables input field

function SupportsBank(protocol, bankCode)
    return protocol == ProtocolWebBanking and bankCode == "IOTA"
end

function InitializeSession(protocol, bankCode, username, username2, password, username3)
    iotaAddress = username:gsub("%s+", "")
end

function ListAccounts(knownAccounts)
    local account = {
        name = "IOTA",
        accountNumber = "IOTA",
        currency = currency,
        portfolio = true,
        type = "AccountTypePortfolio"
    }

    return { account }
end

function RefreshAccount(account, since)
    local s = {}
    prices = requestIOTAPrice()

    for address in string.gmatch(iotaAddress, '([^,]+)') do
        iotaQuantity = requestIOTAQuantityForIOTAAddress(address)

        s[#s + 1] = {
            name = address,
            currency = nil,
            market = "cryptocompare",
            quantity = iotaQuantity,
            price = prices["price_eur"],
        }
    end

    return { securities = s }
end

function EndSession()
end


-- Querry Functions
function requestIOTAPrice()
    response = connection:request("GET", cryptocompareRequestUrl(), {})
    json = JSON(response)

    return json:dictionary()[1]
end

--
function requestIOTAQuantityForIOTAAddress(iotaAddress)
    response = connection:request("GET", iotaRequestUrl(iotaAddress), {})
    html = HTML(response)
    elements = html:xpath("//div[@class='summary-info']/div[3]/span[2]")
    value = elements:get(1):text()
    for s in string.gmatch(value, '%S+') do
        return s
    end
end


-- Helper Functions
function cryptocompareRequestUrl()
    return "https://api.coinmarketcap.com/v1/ticker/iota/?convert=EUR"
end

function iotaRequestUrl(iotaAddress)
    return "https://iotasear.ch/address/" .. iotaAddress
end

