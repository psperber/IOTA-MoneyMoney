-- Inofficial IOTA Extension for MoneyMoney
-- Fetches IOTA quantity for addresses via nodes.iota.cafe
-- Fetches IOTA price in EUR via coinmarketcap API
-- Returns cryptoassets as securities
--
-- Username: IOTA Adresses comma seperated
-- Password: [Whatever]

-- MIT License

-- Copyright (c) 2018 PSperber, aaronk6

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
    version = 0.1,
    description = "Include your IOTAs as cryptoportfolio in MoneyMoney by providing IOTA addresses as usernme (comma seperated) and a random Password",
    services = { "IOTA" }
}

local iotaAddresses
local connection = Connection()
local currency = "EUR" -- fixme: make dynamic if MM enables input field

function SupportsBank(protocol, bankCode)
    return protocol == ProtocolWebBanking and bankCode == "IOTA"
end

function InitializeSession(protocol, bankCode, username, username2, password, username3)
    iotaAddresses = username
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
    local prices = requestIOTAPrice()
    local addresses = strsplit(",%s*", iotaAddresses)
    local balances = requestIOTAQuantitiesForIOTAAddresses(addresses)

    for i,v in ipairs(addresses) do
        s[i] = {
            name = v,
            currency = nil,
            market = "cryptocompare",
            quantity = balances[i] / 1000000, -- convert to MIOTA
            price = prices["price_eur"],
        }
    end

    return { securities = s }
end

function EndSession()
end


-- Query Functions
function requestIOTAPrice()
    response = connection:request("GET", cryptocompareRequestUrl(), {})
    json = JSON(response)

    return json:dictionary()[1]
end

--
function requestIOTAQuantitiesForIOTAAddresses(iotaAddresses)

    local iotaAddressesWithoutChecksum = {}

    -- strip checksums and add quotes
    for i,v in ipairs(iotaAddresses) do
        iotaAddressesWithoutChecksum[i] = '"' .. string.sub(v, 0, 81) .. '"'
    end

    local headers = {}
    headers["X-IOTA-API-Version"] = "1"

    local postContent = '{"command":"getBalances","addresses":['.. strjoin(',', iotaAddressesWithoutChecksum) ..'],"threshold":100}'
    content = connection:request("POST", iotaRequestUrl(), postContent, "application/json", headers)

    json = JSON(content)
    return json:dictionary()["balances"]
end


-- Helper Functions
function cryptocompareRequestUrl()
    return "https://api.coinmarketcap.com/v1/ticker/iota/?convert=EUR"
end

function iotaRequestUrl()
    return "https://nodes.iota.cafe/"
end

-- from http://lua-users.org/wiki/SplitJoin
function strjoin(delimiter, list)
   local len = #list
   if len == 0 then
      return ""
   end
   local string = list[1]
   for i = 2, len do
      string = string .. delimiter .. list[i]
   end
   return string
end

-- from http://lua-users.org/wiki/SplitJoin
function strsplit(delimiter, text)
    local list = {}
    local pos = 1
    if string.find("", delimiter, 1) then -- this would result in endless loops
        error("delimiter matches empty string!")
    end
    while 1 do
        local first, last = string.find(text, delimiter, pos)
        if first then -- found?
            table.insert(list, string.sub(text, pos, first-1))
            pos = last+1
        else
            table.insert(list, string.sub(text, pos))
            break
        end
   end
   return list
end
