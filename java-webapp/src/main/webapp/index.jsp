<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<title>DevOps Workshop App</title>
<style>
  body {
    font-family: Arial, sans-serif;
    margin: 0;
    padding: 20px;
    background-color: #f5f5f5;
    color: #333;
    text-align: center;
  }
  
  .container {
    max-width: 800px;
    margin: 0 auto;
    background-color: white;
    padding: 30px;
    border-radius: 8px;
    box-shadow: 0 0 10px rgba(0,0,0,0.1);
  }
  
  h1 {
    color: #2a5caa;
  }
  
  .info {
    margin-top: 20px;
    padding: 15px;
    background-color: #e8f4f8;
    border-radius: 4px;
  }
  
  .footer {
    margin-top: 30px;
    font-size: 0.8em;
    color: #666;
  }
</style>
</head>
<body>
  <div class="container">
    <h1>Welcome to the DevOps Workshop!</h1>
    <p>This simple Java web application demonstrates a complete CI/CD pipeline.</p>
    
    <div class="info">
      <h2>Environment Information</h2>
      <p>Hostname: <%= java.net.InetAddress.getLocalHost().getHostName() %></p>
      <p>Java Version: <%= System.getProperty("java.version") %></p>
      <p>Server Time: <%= new java.util.Date() %></p>
    </div>
    
    <div class="footer">
      <p>DevOps Workshop - Deployed with Tekton and ArgoCD</p>
    </div>
  </div>
</body>
</html>
