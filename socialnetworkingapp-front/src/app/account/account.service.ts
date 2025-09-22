
import {Observable, of, throwError} from 'rxjs';
import {Injectable} from "@angular/core";
import {HttpClient, HttpErrorResponse, HttpEventType, HttpHeaders} from "@angular/common/http";
import {Account} from "./account";
import {environment} from "../../environments/environment";
import {Login} from "../login/login";
import {Bio} from "../bio/bio";
import { catchError, switchMap } from 'rxjs/operators';
import { AccountUpdateRequest } from './accountUpdateRequest';
import { Education } from '../education/education';
import { Experience } from '../experience/experience';

@Injectable({
  providedIn: 'root'
})

export class AccountService {

  private url = environment.apiBaseUrl + '/accounts';
  constructor(private http: HttpClient) {  }

  public fetchUser(email:string): Observable<Account> {
    return this.http.get<Account>(`${this.url}/find/mail/${email}`);
  }
  public getAllAccounts(): Observable<Account[]> {
    return this.http.get<Account[]>(`${this.url}/all`);
  }
  public getAccountById(account_id: number): Observable<Account> {
    return this.http.get<Account>(`${this.url}/find/id/${account_id}`);
  }

  public getAccountByEmail(email: string): Observable<Account> {
    return this.http.get<Account>(`${this.url}/find/mail/${email}`);
  }

  public getAccountsBySimilarName(keyword: string): Observable<Account[]> {
    return this.http.get<Account[]>(`${this.url}/find/names/${keyword}`);
  }

  // Registration endpoint actually expects a RegistrationRequest (firstName, lastName, email, password, phone, interests[] of Tag objects)
  // We keep the method name for backward compatibility but accept a generic payload.
  public registerAccount(registrationRequest: any): Observable<Account> {
    const httpOptions = { headers: new HttpHeaders({ 'Content-Type': 'application/json' }) };
    const primary = `${environment.apiBaseUrl}/register`;
    return this.http.post<Account>(primary, registrationRequest, httpOptions).pipe(
      catchError(err => {
        // Network error (status 0) -> attempt fallback endpoints
        if (err.status === 0) {
          const fallbacks = [
            primary.replace('https://', 'http://'),
            primary.replace('/api/register', '/register'),
            primary.replace('https://localhost:8443/api', 'http://localhost:8080/api'),
          ];
          return this.tryFallbacks(fallbacks, registrationRequest, httpOptions, 0);
        }
        return throwError(() => err);
      })
    );
  }

  private tryFallbacks(urls: string[], body: any, options: any, index: number): Observable<Account> {
    if (index >= urls.length) {
      return throwError(() => ({ status: 0, message: 'All fallback registration attempts failed' }));
    }
  return (this.http.post<Account>(urls[index], body, { headers: options.headers, responseType: 'json' as const }) as Observable<Account>).pipe(
      catchError(err => {
        if (err.status === 0) {
          return this.tryFallbacks(urls, body, options, index + 1);
        }
        return throwError(() => err);
      })
    );
  }

  public pingHealth(): Observable<boolean> {
    const url = `${environment.apiBaseUrl}/health`;
    return this.http.get(url, { responseType: 'text' }).pipe(
      switchMap(() => of(true)),
      catchError(() => of(false))
    );
  }

  public updateAccount(account: Account): Observable<Account> {
    return this.http.put<Account>(`${this.url}/update`, account);
  }

  public aboutUpdateAccount(account: AccountUpdateRequest): Observable<Account> {

    let httpOptions = { headers: new HttpHeaders(
      { 'Content-Type': 'application/json', })};
    return this.http.put<Account>(`${this.url}/about-update`, account, httpOptions);
  }

  public updatePassword(newPassword: string): Observable<boolean> {
    return this.http.post<boolean>(`${this.url}/update-password`, newPassword);
  }

  public deleteAccountById(account_id: number): Observable<any> {
    return this.http.delete<any>(`${this.url}/delete/${account_id}`);
  }

  public confirmPassword(password : string):Observable<boolean>{
    return this.http.post<boolean>(`${this.url}/confirmation`, password);
  }

  public addBio(bio: string) : Observable<Bio>{
    let httpOptions = { headers: new HttpHeaders(
      { 'Content-Type': 'application/json', })};
    return this.http.post<Bio>(`${this.url}/bio/add`, bio, httpOptions);
  }

  public addEducation(education: Education) : Observable<Account>{
    console.log(education);
    let httpOptions = { headers: new HttpHeaders(
      { 'Content-Type': 'application/json', })};
    return this.http.post<Account>(`${this.url}/education/add`, education, httpOptions);
  }

  public editEducation(education: Education) : Observable<Education>{
    let httpOptions = { headers: new HttpHeaders(
      { 'Content-Type': 'application/json', })};
    return this.http.post<Education>(`${this.url}/education/update`, education, httpOptions);
  }

  public addExperience(experience: Experience) : Observable<Account>{
    let httpOptions = { headers: new HttpHeaders(
      { 'Content-Type': 'application/json', })};
    return this.http.post<Account>(`${this.url}/experience/add`, experience, httpOptions);
  }

  public editExperience(experience: Experience) : Observable<Experience>{
    let httpOptions = { headers: new HttpHeaders(
      { 'Content-Type': 'application/json', })};
    return this.http.post<Experience>(`${this.url}/experience/update`, experience, httpOptions);
  }

  public deleteBio(id: number) {
    return this.http.delete<any>(`${this.url}/bio/delete/${id}`);
  }

  public hideTags() {
    return this.http.put<Account>(`${this.url}/hide-tags`, null);
  }

  public showTags() {
    return this.http.put<Account>(`${this.url}/show-tags`,null);
  }

  public deleteEducation(id: number) {
    return this.http.delete<any>(`${this.url}/education/delete/${id}`);
  }

  public deleteExperience(id: number) {
    return this.http.delete<any>(`${this.url}/experience/delete/${id}`);
  }
}
