-- Enable realtime publication for devices, device_readings, and alerts tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.devices;
ALTER PUBLICATION supabase_realtime ADD TABLE public.device_readings;
ALTER PUBLICATION supabase_realtime ADD TABLE public.alerts;
