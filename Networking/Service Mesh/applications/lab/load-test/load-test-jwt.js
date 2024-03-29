import http from 'k6/http';
import { check, sleep } from 'k6';
export let options = {
  stages: [
    { duration: '10s', target: 1 },
    { duration: '1m30s', target: 20 },
    { duration: '10s', target: 0 },
  ],
};
export default function () {
  var url = 'http://frontend.apps.cluster-ada4.ada4.example.opentlc.com';
  let res=http.get(url);
  var token = 'eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJGSjg2R2NGM2pUYk5MT2NvNE52WmtVQ0lVbWZZQ3FvcXRPUWVNZmJoTmxFIn0.eyJqdGkiOiJkNjlhYWU1YS00MmY1LTQ3ZTAtODdlZC1kZTNkNTE1Njc4NWIiLCJleHAiOjE5MDI2NDEyMzIsIm5iZiI6MCwiaWF0IjoxNTg3MjgxMjMyLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODAvYXV0aC9yZWFsbXMvcXVpY2tzdGFydCIsImF1ZCI6ImN1cmwiLCJzdWIiOiI1ZTc2YWM1Mi1jMDgyLTQyZTgtODI1Yy1lMDc2ZDJhYmU3ODciLCJ0eXAiOiJCZWFyZXIiLCJhenAiOiJjdXJsIiwiYXV0aF90aW1lIjowLCJzZXNzaW9uX3N0YXRlIjoiZTBhODljNWMtMzM1MC00NThiLWJlMzktNTliOTZmMWU2NTA2IiwiYWNyIjoiMSIsImFsbG93ZWQtb3JpZ2lucyI6WyJ2b3Jhdml0LmV4YW1wbGUuY29tIl0sInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJ1bWFfYXV0aG9yaXphdGlvbiIsImFjY291bnQtdmlld2VyIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnsiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19fSwicHJlZmVycmVkX3VzZXJuYW1lIjoib3BlcmF0b3IifQ.jAgL-GEGl8ZLJuFuQR-dyw8gAIRQRyrrI8LJsoO_uFvTEjuRrtTNBPSdEpDw7ZWsR9WDu-hiMdPJKkVRRxM6edllq9kpvDsrI_J7gRvVY7JCOBZ3Yl3VJYFjsjLRF-U83xU7BUnqL2L9jU2IOvIXTIAVaw5qt8yUT8ZQQ4OOomg';
  var params = {
    headers: {
      'Authorization': 'Bearer '+token,
    },
  };
   res=http.get(url,params);
  console.log('status: ' + res.status);
}
