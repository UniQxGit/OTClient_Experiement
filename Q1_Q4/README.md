# Questions 1 - 4

## Question 1: Fix or improve the implementation of the below methods

```lua
local function releaseStorage(player)
    player:setStorageValue(1000, -1)
end

function onLogout(player)
    if player:getStorageValue(1000) == 1 then
        addEvent(releaseStorage, 1000, player)
    end

    return true
end
```

### Response:
```lua
-- Let's make this function more versitile and dynamic to match the function name. Creating a function to set a single value seems redundant.
local function releaseStorage(player)
    if player:getStorageValue(1000) == 1 then
        player:setStorageValue(1000, -1)
    end
end

function onLogout(player)
    -- Let's remove the delay event. If we set such an arbitrary delay value, we can't guarantee that the player object won't be nil at the time of execution.
    releaseStorage(player);
    return true
end
```

### Reasoning:
The original version creates a `releaseStorage` function to suggest that it will be used to release the storage variables of the player, however, there is a condition in `onLogout` to only ever execute for a single variable, this seems redundant and inefficient. It would make more sense to move the conditional check into the `releaseStorage` function, and re-use the releaseStorage function to release other player values as necessary.

`addEvent` used in the original is a TFS server side function registered from the LUAScriptInterface from the C++ Source code `luascript.cpp` that registers events to be executed after a delay. The first parameter is the callback function to be called, the 2nd is the delay, and subsequent paremeters are the inputs to the passed callback function. This however, seems unnecessary here. Unless there is a specific purpose visible for the delay and all clients are aware of this delay, arbitrary delays like this could potentially cause client-server desyncs where the client and server are in different states. 

## Question 2: Fix or improve the implementation of the below method

```lua
function printSmallGuildNames(memberCount)
    -- this method is supposed to print names of all guilds that have less than memberCount max members
    local selectGuildQuery = "SELECT name FROM guilds WHERE max_members < %d;"
    local resultId = db.storeQuery(string.format(selectGuildQuery, memberCount))
    local guildName = result.getString("name")
    print(guildName)
end
```

### Response:
```lua
function printSmallGuildNames(memberCount)
    -- this method is supposed to print names of all guilds that have less than memberCount max members
    local selectGuildQuery = "SELECT name FROM guilds WHERE max_members < %d;"
    local resultId = db.storeQuery(string.format(selectGuildQuery, memberCount))

    -- We need to loop through each value of the result table and print each value.
    if resultId ~= false then
		repeat
            -- The proper syntax for "getString" is (dbQueryResult, valueToRetrieve)
			local guildName = result.getString(resultId, "name")
			print(guildName);
		until not result.next(resultId)
        -- Make sure to free the results table so that there isn't any cross contamination between queries the next time a storeQuery is called.
		result.free(resultId)
	end
end
```

### Reasoning:
The original function only prints a single, first entry of the result table. However, if the intention is to print all the members of the query result, we need to modify the code to loop through each value of the results using result.next(resultId). Additionally, the syntax for result.getString("name") is incorrect, we also need to pass the original resultId query result value. Finally, before we exit this function, we need to ensure that we're freeing the resultId so that subsuquent calls to db::storeQuery won't have cross contamination from previous queries. 

## Question 3: Fix or improve the name and the implementation of the below method

```lua
function do_sth_with_PlayerParty(playerId, membername)
    player = Player(playerId)
    local party = player:getParty()

    for k,v in pairs(party:getMembers()) do
        if v == Player(membername) then
        party:removeMember(Player(membername))
        end
    end
end
```

### Response:
```lua
--Maybe I just don't know gaming lingo enough, but do_sth doesn't make this function's purpose clear. Let's rename it to something more focused, like "kickFromPlayerPartyByName"
function kickFromPlayerPartyByName(playerId, membername)
    player = Player(playerId)
    local party = player:getParty()

    -- Make sure to safeguard this function in case the player doesn't have a party. 
    if party == nil then
		return false
	end

    -- Utilize the ipairs key value pair to iterate over the members, pairs seems unnecessary. 
    for _, member in ipairs(party:getMembers()) do
        -- uses the member function getName to access the name directly, creating a new player instance every time is a waste of memory. 
		if membername == member:getName() then
            --removeMember is not a valid member of Party. Lets change that to `LeaveParty`
            party:leaveParty(member)
            -- Break out of the loop once the party member has been found.
            break
        end
	end
end
```

### Reasoning:
Firstly, function names should be absolutely clear such that anyone looking at it will be able to recognize the purpose of the function at first glance even without additional context, based on the code, I gathered that the function attempts to remove a member of a given player's party by a party members name, rather than the full player object, so I've renamed the function to something more appropriate and descriptive, like kickFromPlayerPartyByName. 

Looping through the party:getMembers table, `pairs` seems unnecessary here. Its safe to assume that `getMembers` will return a sequential numerical key array, and ipairs is more consistent and efficient for this use case. 

We also use `getName()` rather than `Player(membername)` firstly, because its an inefficient use of memory to create a new instance of player when you can just as easily access the original variables in memory. Secondly, `getMembers` returns a table of player objects, and not player names, so its a type mismatch to compare the value `v` which is of type `Player` to `membername` of type `string`. 

Finally, an additional minor change we can make is to break out of the loop once a party member is found. Its wasteful to loop through the entire array once you've found what you need. 

## Question 4: Assume all method calls work fine. Fix the memory leak issue in below method

```cpp
void Game::addItemToPlayer(const std::string& recipient, uint16_t itemId)
{
    Player* player = g_game.getPlayerByName(recipient);
    if (!player) {
        player = new Player(nullptr);
        if (!IOLoginData::loadPlayerByName(player, recipient)) {
            return;
        }
    }

    Item* item = Item::CreateItem(itemId);
    if (!item) {
        return;
    }

    g_game.internalAddItem(player->getInbox(), item, INDEX_WHEREEVER, FLAG_NOLIMIT);

    if (player->isOffline()) {
        IOLoginData::savePlayer(player);
    }
}
```

### Response:
```cpp
void Game::addItemToPlayer(const std::string& recipient, uint16_t itemId)
{
    Player* player = g_game.getPlayerByName(recipient);
    if (!player) {
        player = new Player(nullptr);
        if (!IOLoginData::loadPlayerByName(player, recipient)) {
            // Free up the memory allocated by the player pointer. 
            delete player;
            return;
        }
    }

    Item* item = Item::CreateItem(itemId);
    if (!item) {
        // Free up the memory allocated by the item pointer. 
        delete item;
        return;
    }

    g_game.internalAddItem(player->getInbox(), item, INDEX_WHEREEVER, FLAG_NOLIMIT);

    if (player->isOffline()) {
        IOLoginData::savePlayer(player);
        // Free up the memory allocated by the player pointer. 
        delete player;
    }
}
```

### Reasoning:
When memory is allocated dynamically utilizing the `new` keyword, we need to ensure that memory leaks don't happen in the case that a pointer goes out of scope without properly deallocating unused memory. The `Player* player` pointer is dynamically allocated here through the `new` keyword, and we can see a possible memory leak as we return from the function if a player load through `IOLoginData::loadPlayerByName` fails. Near the end of the function, we ensure to also deallocate the memory through the `delete` keyword if the player is offline. 

`Item::CreateItem()` similarly allocates memory dynamically within the function by returning a `new` item, and needs to be deallocated through the `delete` keyword if the item has not been found. 