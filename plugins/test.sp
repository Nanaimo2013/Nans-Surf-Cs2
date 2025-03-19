#include <sourcemod>

public Plugin myinfo = {
    name = "Test Plugin",
    author = "Your Name",
    description = "Test",
    version = "1.0",
    url = ""
};

public void OnPluginStart() {
    // Empty
}

void ShowTestMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Test);
    menu.SetTitle("Test Menu");
    menu.AddItem("1", "Option 1");
    menu.AddItem("2", "Option 2");
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Test(Menu menu, MenuAction action, int client, int item)
{
    return 0;
}