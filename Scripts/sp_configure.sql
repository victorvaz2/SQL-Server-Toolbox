--==========================================================================
-- SP_CONFIGURE
--
--Turn advanced options off after you use it: 
--sp_configure 'show advanced options', (1/0)
--==========================================================================

--sp_configure @name @value

/*
@name = backup compresion default
@value = 1
Defaults all backups to having compression.
*/

/*
@name = blocked process threshold (s)
@value = 
The threshold from which processes blocked higher than @value will be sent to the blocked processes report. 
Nice to start around 5s or so and get a feel for the average blocks.
*/

/*
@name = clr enabled
@value = 1
To be able to use CLR functions and sp that we write. Native CLR works naturally.
*/

/*
@name = database mail xps
@value = 1
In order to use database mail.
*/

/*
@name = fill factor (%)
@value = (0 - 100)
Indexes need space. Whenever you create an index you allocate pages to contain it. It'll fill @fill_factor % of it with data,
 leaving the rest of the page for extra data that might get inserted or updated. Whenever it reaches 100%, it splits and gets 
 fragmented.
Recommended to use 80 - 90. 
*/

/*
@name = max degree of parallelism
@value = 
Varies a lot. Consider the number of CPUs avaliable but try not to use it all, so a single process can't have all the cores for itself.
Maybe around 1/6 of the total CPU count?
*/


/*
@name = remote admin connections
@value = 0/1
Leaves a single CPU avaliable for the admin to use.
In case any processes takes up your server resources and you can't even log in, having this turned on will make it avaliable
 to have an entrance.
*/

/*
@name = xp_cmdshell
@value = 0/1
Allows DOS acess to your server. Only usable by the admin. Extremely insecure, dangerous.
*/