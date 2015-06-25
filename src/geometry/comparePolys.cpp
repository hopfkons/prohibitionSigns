#include <iostream>
#include <cstdlib>
#include <string>
#include <CGAL/Exact_predicates_inexact_constructions_kernel.h>
#include <CGAL/Exact_predicates_exact_constructions_kernel.h>
#include <CGAL/Boolean_set_operations_2.h>
#include <list>

//typedef CGAL::Exact_predicates_exact_constructions_kernel Kernel;
typedef CGAL::Simple_cartesian<double> Kernel;
typedef Kernel::Point_2                                   Point_2;
typedef CGAL::Polygon_2<Kernel>                           Polygon_2;
typedef CGAL::Polygon_with_holes_2<Kernel>                Polygon_with_holes_2;
typedef std::list<Polygon_with_holes_2>                   Pwh_list_2;

using namespace std;

template<class Kernel, class Container>
void print_polygon (const CGAL::Polygon_2<Kernel, Container>& P)
{
    typename CGAL::Polygon_2<Kernel, Container>::Vertex_const_iterator vit;
    std::cout << "[ " << P.size() << " vertices:";
    for (vit = P.vertices_begin(); vit != P.vertices_end(); ++vit)
    std::cout << " (" << *vit << ')';
    std::cout << " ]" << std::endl;
}

template<class Kernel, class Container>
void print_polygon_with_holes(const CGAL::Polygon_with_holes_2<Kernel, Container> & pwh)
{
    if (! pwh.is_unbounded()) {
        std::cout << "{ Outer boundary = ";
        print_polygon (pwh.outer_boundary());
    } else
    std::cout << "{ Unbounded polygon." << std::endl;
    typename CGAL::Polygon_with_holes_2<Kernel,Container>::Hole_const_iterator hit;
    unsigned int k = 1;
    std::cout << " " << pwh.number_of_holes() << " holes:" << std::endl;
    for (hit = pwh.holes_begin(); hit != pwh.holes_end(); ++hit, ++k) {
        std::cout << " Hole #" << k << " = ";
        print_polygon (*hit);
    }
    std::cout << " }" << std::endl;
}

template<class Kernel, class Container>
double area_polygon_with_holes(const CGAL::Polygon_with_holes_2<Kernel, Container> & pwh)
{
    // maybe we should assert that (! pwh.is_unbounded()) ...
    double area = fabs(pwh.outer_boundary().area());
    typename CGAL::Polygon_with_holes_2<Kernel,Container>::Hole_const_iterator hit;
    unsigned int k = 1;
    for (hit = pwh.holes_begin(); hit != pwh.holes_end(); ++hit, ++k) {
        area -= fabs(hit->area());
    }
    return area;
}

//fabs(it->outer_boundary().area());

int main(int argc, char* argv[])
{
    if (argc < 2) {
        cerr << "usage: " << argv[0] << " FILE_WITH_POLYGONS" << endl;
        return 1;
    } else {
        Polygon_2 P[2];
        Polygon_2 Q;
        int pIdx = 0;
        FILE* pdat = fopen(argv[1], "r");
        
        if (pdat) {
            while (!feof(pdat) && pIdx < 2) {
                double x,y;
                int dtRead = fscanf(pdat, "%lf %lf", &x, &y);
                if (dtRead == 2) {
                    P[pIdx].push_back( Point_2(10000*(x-54),10000*(y-9)));
                } else {
                    fgetc(pdat);
                    //cout << "read " << fgetc(pdat) << endl;
                    pIdx++;
                }
            }
            fclose(pdat);
            /*
            cout << "Polygon P: " << endl;
            print_polygon(P[0]);
            cout << "Polygon Q: " << endl;
            print_polygon(P[1]);
            cout << "area P = " << P[0].area() << "  area Q = " << P[1].area() << endl;
            */
            if (CGAL::do_intersect (P[0], P[1])) {
                Pwh_list_2                  intR;
                Pwh_list_2::const_iterator  it;
                CGAL::intersection (P[0], P[1], std::back_inserter(intR)); // nmaybe be multiple polys
                double areaIntersection = 0.0;
                for (it = intR.begin(); it != intR.end(); ++it) {
                    areaIntersection += area_polygon_with_holes(*it);
                }
                double areaP0 = fabs(P[0].area());
                double areaP1 = fabs(P[1].area());
                
                if (areaIntersection < 1e-30) { // should rarely happen since interiors are known to overlap...
                    cout << "0 ; area too small: " << areaIntersection << endl;
                } else {
                    
                    double precision = areaIntersection / areaP0; // P0 ist berechnete Region
                    double recall = areaIntersection / areaP1; // (1e10/(1e10+(areaP1-areaIntersection)));
                    double f1 = (2 * precision * recall) / (precision + recall);
                    /*
                    cout << "areaP0 = " << areaP0 << "  areaP1 = " << areaP1 << endl;
                    cout << "intersection = " << areaIntersection << endl;
                    cout << "precision = " << precision << endl;
                    cout << "recall = " << recall << endl;
                     */
                    cout << f1 << endl;
                    
//                    cout << "(" << areaIntersection / areaP0 << " . " << areaIntersection / areaP1 << ")" << endl;
                }
                // cout << "P0: " << areaP0 << " P1: " << areaP1 << "  Intersection: " << areaIntersection << endl;
            } else {
                cout << "0 ; no overlap" << endl;
            }
        } else {
            cerr << "ERROR opening file " << argv[1] << endl;
        }
    }
    return 0;
}
