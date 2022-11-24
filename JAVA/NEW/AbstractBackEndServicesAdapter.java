/**
 * 
 */
package it.poste.camel.processors;

import java.beans.Introspector;
import java.beans.PropertyDescriptor;
import java.lang.reflect.Method;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.camel.Exchange;
import org.springframework.http.HttpHeaders;

/**
 * @author m.curcio
 *
 */
public abstract class AbstractBackEndServicesAdapter {

	/**
	 * @param exchange
	 * @return
	 */
	public HttpHeaders prepareResponseHeaders(Exchange exchange) {
		HttpHeaders result = new HttpHeaders();
		result.add("correlation-id", exchange.getOut().getHeader("correlation-id", String.class));
		return result;
	}

	@SuppressWarnings({ "unchecked", "rawtypes" })
	public static Object trimReflective(Object object) throws Exception {
		if (object == null)
			return null;

		Class<? extends Object> c = object.getClass();

		for (PropertyDescriptor propertyDescriptor : Introspector.getBeanInfo(c, Object.class).getPropertyDescriptors()) {
			Method method = propertyDescriptor.getReadMethod();
			String name = method.getName();

			if (method.getReturnType().equals(String.class)) {
				String property = (String) method.invoke(object);
				if (property != null) {
					Method setter = c.getMethod("set" + name.substring(3),new Class<?>[] { String.class });
					if (setter != null)
						setter.invoke(object, property.trim());
				}
			}else if(List.class.isAssignableFrom(method.getReturnType())){
				List listPropery = (List) method.invoke(object);

				if(listPropery != null) {
					Iterator<Object> it = listPropery.iterator();

					while(it.hasNext()) {
						Object currentObj = it.next();
						trimReflective(currentObj);
					}
				}
			}else if (method.getReturnType().equals(Map.class)) {
				Map mapProperty = (Map) method.invoke(object);
				if (mapProperty != null) {
					for (int index = 0; index < mapProperty.keySet().size(); index++) {
						if (mapProperty.keySet().toArray()[index] instanceof String) {
							String element = (String) mapProperty.keySet().toArray()[index];
							if (element != null) {
								mapProperty.put(element.trim(),
										mapProperty.get(element));
								mapProperty.remove(element);
							}
						} else {
							trimReflective(mapProperty.get(index));
						}
					}
					for (Map.Entry entry : (Set<Map.Entry>) mapProperty.entrySet()) {

						if (entry.getValue() instanceof String) {
							String element = (String) entry.getValue();
							if (element != null) {
								entry.setValue(element.trim());
							}
						} else {
							trimReflective(entry.getValue());
						}
					}
				}
			}else if (method.getReturnType().isArray()
					&& !method.getReturnType().isPrimitive()
					&& !method.getReturnType().equals(String[].class)
					&& !method.getReturnType().equals(byte[].class)) 
			{
				if (method.invoke(object) instanceof Object[]) {
					Object[] objectArray = (Object[]) method.invoke(object);
					if (objectArray != null) {
						for (Object obj : (Object[]) objectArray) {
							trimReflective(obj);
						}
					}
				}
			}else{  
				Object property = (Object) method.invoke(object);
				if (property != null) {
					trimReflective(property);
				}
			}
		}
		return object;
	}
}
