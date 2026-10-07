package com.raccord.rc01msauth.dto;

public class LoginRequest {
    private String mail;
    private String contrasena;
    public LoginRequest() {}
    public String getMail() { return mail; }
    public void setMail(String mail) { this.mail = mail; }
    public String getContrasena() { return contrasena; }
    public void setContrasena(String contrasena) { this.contrasena = contrasena; }
}
