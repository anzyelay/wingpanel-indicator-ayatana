# Wingpanel Ayatana-Compatibility Indicator (Community Version)

<h1>Description:</h1>
Keep compatibility with ubuntu/unity indicators on Patapua OS wingpanel.
If you want to install applications with indicators like weather forecast, redshift, social networks... this plug-in let these indicators appear in your panel.

<p align="center"><img src="screenshot.png"/> </p>

<b>Important:</b> To add support for Legacy icons (Wine, PlayOnLinux) see here : <a href="https://github.com/msmaldi/wingpanel-indicator-na-tray">msmaldi/wingpanel-indicator-na-tray</a>
, this project fork from here : <a href="https://github.com/Lafydev/wingpanel-indicator-ayatana">Lafydev</a>
<h2>Dependencies</h2>

You'll need the following dependencies :

<pre>sudo apt-get install libglib2.0-dev libgranite-dev libindicator3-dev </pre>

- version odin(6) : 
  
  <pre>sudo apt-get install libwingpanel-dev indicator-application</pre>

<h1>Easy Install (user only)</h1>
1. Download the deb file from your version :

- <a href="">wingpanel-indicator-ayatana.*amd64.deb</a> for hera and previous  
- OR <a href="">wingpanel-indicator-ayatana.*odin.deb</a>  

and launch install:<br/>

<pre>sudo dpkg -i ./wingpanel-indicator-ayatana*.deb</pre>

<h2>Parameters for Pantheon (eos)</h2>
2. You need to add Pantheon to the list of desktops abled to work with indicators :<br/>
<ul>
<li>With autostart (thanks to JMoerman) </li>
just add /usr/lib/x86_64-linux-gnu/indicator-application/indicator-application-service as custom command to the auto start applications in the system settings.
System settings -> "Applications" -> "Startup" -> "Add Startup App…" -> "Type in a custom command".
<br/>

<li>With the terminal (thanks to ankurk91) </li>
Open Terminal and run the following commands.
<pre>mkdir -p ~/.config/autostart
cp /etc/xdg/autostart/indicator-application.desktop ~/.config/autostart/
sed -i 's/^OnlyShowIn.*/OnlyShowIn=Unity;GNOME;Pantheon;/' ~/.config/autostart/indicator-application.desktop
</pre><br/>

<li>Editing files (change system settings!)</li>
<pre>sudo nano /etc/xdg/autostart/indicator-application.desktop</pre>
Search the parameter: OnlyShowIn= and add "Pantheon" at the end of the line : 
<pre>OnlyShowIn=Unity;GNOME;Pantheon;</pre>
Save your changes (Ctrl+X to quit + Y(es) save the changes + Enter to valid the filename).<br/>
</ul>

3.<b>reboot</b>.

<h1>Build and install (developer)</h1>

1. Download the last release (zip) and extract files 

<h2>Dependencies</h2>
2. You'll need all the dependencies from easy install and these to build : 
<pre>sudo apt-get install valac gcc meson </pre/>

<h2>Build with meson</h2>
3. Open a Terminal in the extracted folder, build your application with meson and install it with ninja:<br/>

<pre>meson build --prefix=/usr
cd build
ninja
sudo ninja install
</pre>

4. Follow step 2 from easy install (parameters) and reboot.

<h2>uninstall</h2>
Open a terminal in the build folder.
<pre>sudo ninja uninstall</pre>

Reboot or restart wingpanel : 
Version Odin(6): <pre>killall io.elementary.wingpanel</pre>

# requirement settings by some application 
## neteasy-music
```sh
sed -ri 's/^Exec=(.*)/Exec=env XDG_CURRENT_DESKTOP=Unity \1/g' /usr/share/applications/neteasy-cloud-music.desktop
```

